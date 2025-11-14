// Copyright (c) 2025 A Solution IT LLC. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for full license information.
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using Launcher.Controls;
using Launcher.Services;
using Launcher.Attributes;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Security; // Needed for SecureString checks and SecurityException
using System.Text;
using System.Text.RegularExpressions;
using System.Runtime.CompilerServices;
using Microsoft.Win32;
using System.Windows.Threading;
using Win32 = Microsoft.Win32;
using System.Management.Automation.Language; // Required for Parser and AST nodes
using System.Collections.Specialized;
using System.Runtime.InteropServices;

namespace Launcher.ViewModels
{
    public class MainWindowViewModel : INotifyPropertyChanged
    {
        private int _currentStep = 1;
        private string _windowTitle = "PoshWizard";
        private object _currentPage;
        private string _nextButtonText = "Next";
        private bool _canGoBack = false;
        private string _scriptPath;
        private readonly ReflectionService _reflectionService;
        private readonly IDialogService _dialogService;
        private List<WizardStep> _wizardSteps = new List<WizardStep>();

        private ScriptData _parsedData;
        private int _currentPageIndex = -1;

        // Branding fields
        private string _windowTitleIconPath;
        private string _sidebarHeaderText = "PoshWizard";
        private string _sidebarHeaderIconPath;
        private string _sidebarHeaderIconGlyph;
        private string _sidebarHeaderIconOrientation = "Left";

        // Live execution fields
        private PowerShell _currentPowerShell;
        private Runspace _currentRunspace;
        private System.IO.StreamWriter _structuredLogWriter;
        private readonly object _logLock = new object();
        private ExecutionConsoleViewModel _consoleVm;
        private string _structuredLogPath;
        // Subscriptions for dynamic CanExecute updates based on parameter changes
        private GenericFormViewModel _subscribedForm;
        private readonly HashSet<ParameterViewModel> _subscribedParams = new HashSet<ParameterViewModel>();
        
        // Dynamic parameter fields (Phase 2)
        private DynamicParameterManager _dynamicParameterManager;
        private Runspace _dynamicParameterRunspace;
        private Dictionary<string, ParameterInfo> _dynamicParametersMap; // Maps param name to ParameterInfo
        private Dictionary<string, ParameterViewModel> _parameterViewModels; // Maps param name to ViewModel
        
        // Execution result storage (for Module API)
        private System.Collections.Generic.List<object> _executionResults = new System.Collections.Generic.List<object>();
        public string LastExecutionResult { get; private set; }
        
        // Security fields
        private DateTime? _scriptExecutionStartTime;
        private string _scriptHash;
        private DateTime? _scriptLoadTime;
        
        // Security: Control script execution mode
        public bool AllowUnrestrictedExecution { get; set; } = true;
        
        // Progress indicator fields
        private bool _isProcessing = false;
        private string _processingMessage = "Loading...";

        public event PropertyChangedEventHandler PropertyChanged;

        // Event to notify UI of theme changes for toggle synchronization
        public event EventHandler ThemeChanged;

        public ObservableCollection<StepItem> Steps { get; private set; }
        public Dictionary<string, object> FormData { get; private set; }
        
        // Cache for page ViewModels to prevent recreation on navigation
        private Dictionary<int, object> _pageCache = new Dictionary<int, object>();
        
        public readonly ICommand NextCommand;
        public readonly ICommand PreviousCommand;
        public readonly ICommand LoadScriptCommand;
        public readonly ICommand FinishCommand;

        public int CurrentStep
        {
            get => _currentStep;
            set
            {
                if (_currentStep == value || Steps == null) return;

                int previousStep = _currentStep;
                _currentStep = value;
                OnPropertyChanged(nameof(CurrentStep));
                OnPropertyChanged(nameof(ProgressPercentage));
                OnPropertyChanged(nameof(ProgressText));

                _currentPageIndex = _currentStep - 1;
                LoggingService.Trace($"CurrentStep set to {_currentStep}, _currentPageIndex updated to {_currentPageIndex}", component: "MainWindowViewModel");

                UpdateStepCurrentState(previousStep, _currentStep);

                if (_wizardSteps.Any())
                {
                    UpdateCurrentPage();
                }

                (NextCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (PreviousCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (FinishCommand as RelayCommand)?.RaiseCanExecuteChanged();
            }
        }

        public string SidebarHeaderIconOrientation
        {
            get => _sidebarHeaderIconOrientation;
            set
            {
                var normalized = NormalizeOrientation(value);
                if (_sidebarHeaderIconOrientation == normalized) return;
                _sidebarHeaderIconOrientation = normalized;
                OnPropertyChanged(nameof(SidebarHeaderIconOrientation));
            }
        }

        private static string NormalizeOrientation(string orientation)
        {
            var normalized = (orientation ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(normalized))
            {
                return "Left";
            }

            switch (normalized.ToLowerInvariant())
            {
                case "left":
                    return "Left";
                case "right":
                    return "Right";
                case "top":
                    return "Top";
                case "bottom":
                    return "Bottom";
                default:
                    return "Left";
            }
        }

        public int TotalSteps => Steps?.Count ?? 1;

        public double ProgressPercentage => TotalSteps > 0 ? ((double)CurrentStep / TotalSteps) * 100.0 : 0.0;

        public string ProgressText => $"Step {CurrentStep} of {TotalSteps}";

        private string ResolvePathRelativeToScript(string path)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(path)) return null;
                if (System.IO.Path.IsPathRooted(path)) return path;
                string scriptDir = System.IO.Path.GetDirectoryName(ScriptPath);
                string abs = System.IO.Path.GetFullPath(System.IO.Path.Combine(scriptDir ?? string.Empty, path));
                return abs;
            }
            catch (Exception ex)
            {
                LoggingService.Warn($"Failed to resolve path '{path}' relative to script: {ex.Message}", component: "MainWindowViewModel");
                return null;
            }
        }

        public string WindowTitle
        {
            get => _windowTitle;
            set
            {
                _windowTitle = value;
                OnPropertyChanged(nameof(WindowTitle));
            }
        }

        public string WindowTitleIconPath
        {
            get => _windowTitleIconPath;
            set
            {
                if (_windowTitleIconPath == value) return;
                _windowTitleIconPath = value;
                OnPropertyChanged(nameof(WindowTitleIconPath));
            }
        }

        public string SidebarHeaderText
        {
            get => _sidebarHeaderText;
            set
            {
                if (_sidebarHeaderText == value) return;
                _sidebarHeaderText = value;
                OnPropertyChanged(nameof(SidebarHeaderText));
            }
        }

        public string SidebarHeaderIconPath
        {
            get => _sidebarHeaderIconPath;
            set
            {
                if (_sidebarHeaderIconPath == value) return;
                _sidebarHeaderIconPath = value;
                OnPropertyChanged(nameof(SidebarHeaderIconPath));
                
                // Auto-detect if it's a glyph (starts with &#x) and convert to Unicode character
                if (!string.IsNullOrEmpty(value) && value.StartsWith("&#x") && value.EndsWith(";"))
                {
                    try
                    {
                        // Extract hex code: &#xE1D3; -> E1D3
                        string hexCode = value.Substring(3, value.Length - 4);
                        int charCode = Convert.ToInt32(hexCode, 16);
                        string glyphChar = char.ConvertFromUtf32(charCode);
                        LoggingService.Info($"Converting icon glyph: {value} -> hex:{hexCode} -> char:{charCode} -> glyph:{glyphChar}", component: "MainWindowViewModel");
                        SidebarHeaderIconGlyph = glyphChar;
                    }
                    catch (Exception ex)
                    {
                        LoggingService.Error($"Failed to convert icon glyph: {value}", ex, component: "MainWindowViewModel");
                        SidebarHeaderIconGlyph = null;
                    }
                }
                else
                {
                    LoggingService.Info($"Icon path set (not a glyph): {value}", component: "MainWindowViewModel");
                }
            }
        }

        public string SidebarHeaderIconGlyph
        {
            get => _sidebarHeaderIconGlyph;
            set
            {
                if (_sidebarHeaderIconGlyph == value) return;
                _sidebarHeaderIconGlyph = value;
                OnPropertyChanged(nameof(SidebarHeaderIconGlyph));
            }
        }

        public object CurrentPage
        {
            get => _currentPage;
            set
            {
                // Unsubscribe from previous form parameter changes
                if (_subscribedForm != null)
                {
                    UnsubscribeFromFormParameters();
                }

                _currentPage = value;
                OnPropertyChanged(nameof(CurrentPage));

                // Subscribe to new form parameter changes to keep CanExecute in sync
                if (_currentPage is GenericFormViewModel newForm)
                {
                    SubscribeToFormParameters(newForm);
                }

                (NextCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (PreviousCommand as RelayCommand)?.RaiseCanExecuteChanged();
                (FinishCommand as RelayCommand)?.RaiseCanExecuteChanged();
            }
        }

        public string NextButtonText
        {
            get => _nextButtonText;
            set
            {
                _nextButtonText = value;
                OnPropertyChanged(nameof(NextButtonText));
            }
        }

        public bool CanGoBack
        {
            get => _canGoBack;
            set
            {
                _canGoBack = value;
                OnPropertyChanged(nameof(CanGoBack));
            }
        }

        public string ScriptPath
        {
            get => _scriptPath;
            set
            {
                if (_scriptPath == value) return;
                _scriptPath = value;
                OnPropertyChanged(nameof(ScriptPath));
                if (!string.IsNullOrEmpty(_scriptPath))
                {
                    LoadScript(_scriptPath);
                }
            }
        }

        /// <summary>
        /// Gets or sets whether a background operation is in progress.
        /// </summary>
        public bool IsProcessing
        {
            get => _isProcessing;
            set
            {
                if (_isProcessing == value) return;
                _isProcessing = value;
                OnPropertyChanged(nameof(IsProcessing));
            }
        }

        /// <summary>
        /// Gets or sets the message to display during background operations.
        /// </summary>
        public string ProcessingMessage
        {
            get => _processingMessage;
            set
            {
                if (_processingMessage == value) return;
                _processingMessage = value;
                OnPropertyChanged(nameof(ProcessingMessage));
            }
        }

        public MainWindowViewModel()
        {
            Steps = new ObservableCollection<StepItem>();
            FormData = new Dictionary<string, object>();
            _reflectionService = new ReflectionService();
            _dialogService = new DialogService();

            NextCommand = new RelayCommand(ExecuteNext, CanExecuteNext);
            PreviousCommand = new RelayCommand(ExecutePrevious, CanExecutePrevious);
            LoadScriptCommand = new RelayCommand(ExecuteLoadScript);
            FinishCommand = new RelayCommand(Finish, CanFinish);

            System.Windows.Input.CommandManager.InvalidateRequerySuggested();
            LoggingService.Info("MainWindowViewModel created.", component: "MainWindowViewModel");
        }

        public void SetStepsFromScript(List<WizardStep> wizardSteps, string scriptPath)
        {
            try
            {
                LoggingService.Info("SetStepsFromScript called", component: "MainWindowViewModel");
                _wizardSteps = wizardSteps ?? new List<WizardStep>();
                Steps.Clear();
                FormData.Clear();
                _pageCache.Clear(); // Clear cached pages when loading new script
                SidebarHeaderIconOrientation = "Left"; // Reset orientation to default
                // Derive a friendly title from the script name (branding can override later)
                WindowTitle = System.IO.Path.GetFileNameWithoutExtension(scriptPath) + " Wizard";
                LoggingService.Info($"Adding {_wizardSteps.Count} steps from script", component: "MainWindowViewModel");

                int stepNumber = 1;
                foreach (var step in _wizardSteps)
                {
                    LoggingService.Info($"Adding step {stepNumber}: {step.Title} (Order: {step.Order})", component: "MainWindowViewModel");
                    
                    // Convert icon glyph if present
                    string iconGlyph = null;
                    
                    // Prioritize IconGlyph property if set
                    string glyphSource = !string.IsNullOrEmpty(step.IconGlyph) ? step.IconGlyph : step.IconPath;
                    
                    if (!string.IsNullOrEmpty(glyphSource) && glyphSource.StartsWith("&#x") && glyphSource.EndsWith(";"))
                    {
                        try
                        {
                            string hexCode = glyphSource.Substring(3, glyphSource.Length - 4);
                            int charCode = Convert.ToInt32(hexCode, 16);
                            iconGlyph = char.ConvertFromUtf32(charCode);
                        }
                        catch (Exception ex)
                        {
                            LoggingService.Error($"Failed to convert icon glyph: {glyphSource}", ex, component: "MainWindowViewModel");
                        }
                    }
                    
                    Steps.Add(new StepItem
                    {
                        StepNumber = stepNumber,
                        Title = step.Title,
                        IconGlyph = iconGlyph,
                        ShowConnector = stepNumber < _wizardSteps.Count,
                        IsCurrent = (stepNumber == 1)
                    });
                    stepNumber++;
                }
                
                // Notify UI of step count changes
                OnPropertyChanged(nameof(TotalSteps));
                OnPropertyChanged(nameof(ProgressPercentage));
                OnPropertyChanged(nameof(ProgressText));
                
                LoggingService.Info("SetStepsFromScript completed successfully", component: "MainWindowViewModel");
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in SetStepsFromScript", ex, component: "MainWindowViewModel");
                CurrentPage = new ErrorViewModel("Error setting up steps: " + ex.Message);
                Steps.Clear();
            }
        }

        private void InitializeSteps()
        {
            try
            {
                // Default steps if no script is provided
                Steps.Add(new StepItem { StepNumber = 1, Title = "Personal Info", ShowConnector = true });
                Steps.Add(new StepItem { StepNumber = 2, Title = "Delivery Address", ShowConnector = true });
                Steps.Add(new StepItem { StepNumber = 3, Title = "Billing Address", ShowConnector = true });
                Steps.Add(new StepItem { StepNumber = 4, Title = "Payment", ShowConnector = true });
                Steps.Add(new StepItem { StepNumber = 5, Title = "Confirmation", ShowConnector = false });
                
                // Notify UI of step count changes
                OnPropertyChanged(nameof(TotalSteps));
                OnPropertyChanged(nameof(ProgressPercentage));
                OnPropertyChanged(nameof(ProgressText));
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in InitializeSteps", ex, component: "MainWindowViewModel");
            }
        }

        private void UpdateCurrentPage()
        {
            LoggingService.Trace(">>> UpdateCurrentPage START", component: "MainWindowViewModel"); 
            if (_parsedData == null || _parsedData.WizardSteps == null || _currentPageIndex < 0 || _currentPageIndex >= _parsedData.WizardSteps.Count)
            {
                CurrentPage = null;
                LoggingService.Trace("<<< UpdateCurrentPage END (no valid data or index)", component: "MainWindowViewModel"); // Log exit
                UpdateNavigationButtonVisibility();
                return;
            }

            var currentStepInfo = _parsedData.WizardSteps[_currentPageIndex];
            LoggingService.Trace($"  - Processing Page Index: {_currentPageIndex}, Title: \'{currentStepInfo?.Title}\', Type: \'{currentStepInfo?.PageType}\'", component: "MainWindowViewModel");

            // Check cache first - reuse existing page ViewModels
            if (_pageCache.ContainsKey(_currentPageIndex))
            {
                LoggingService.Info($"Using CACHED page for index {_currentPageIndex} ('{currentStepInfo?.Title}')", component: "MainWindowViewModel");
                CurrentPage = _pageCache[_currentPageIndex];
                
                // CRITICAL: Reload values from FormData to sync cached ParameterViewModels
                if (CurrentPage is GenericFormViewModel cachedForm)
                {
                    foreach (var pvm in cachedForm.Parameters)
                    {
                        if (FormData.TryGetValue(pvm.Name, out object savedValue))
                        {
                            LoggingService.Trace($"Reloading cached param '{pvm.Name}': '{savedValue}'", component: "MainWindowViewModel");
                            
                            if (pvm.IsPassword && savedValue is System.Security.SecureString ss)
                            {
                                pvm.SecureValue = ss;
                            }
                            else if (pvm.IsSwitch || pvm.ParameterType == typeof(bool))
                            {
                                if (savedValue is bool boolVal)
                                    pvm.BoolValue = boolVal;
                                else if (savedValue is string strVal && bool.TryParse(strVal, out bool parsedBool))
                                    pvm.BoolValue = parsedBool;
                                LoggingService.Debug($"UpdateCurrentPage - Restoring Switch '{pvm.Name}': savedValue={savedValue}, setting BoolValue={pvm.BoolValue}", component: "MainWindowViewModel");
                            }
                            else if (pvm.IsMultiSelect && pvm.CheckableItems != null)
                            {
                                // For multi-select, manually update CheckableItems to match saved value
                                var selectedValues = new System.Collections.Generic.HashSet<string>(System.StringComparer.OrdinalIgnoreCase);
                                
                                // Handle both array and string formats
                                if (savedValue is System.Array savedArray)
                                {
                                    // Extract values from array
                                    foreach (var item in savedArray)
                                    {
                                        if (item != null && !string.IsNullOrWhiteSpace(item.ToString()))
                                        {
                                            selectedValues.Add(item.ToString().Trim());
                                        }
                                    }
                                    LoggingService.Info($"Syncing {pvm.CheckableItems.Count} CheckableItems for '{pvm.Name}' from array: [{string.Join(",", selectedValues)}]", component: "MainWindowViewModel");
                                }
                                else
                                {
                                    // Fallback to string parsing
                                    string savedStr = savedValue?.ToString() ?? string.Empty;
                                    if (!string.IsNullOrEmpty(savedStr))
                                    {
                                        foreach (var val in savedStr.Split(new[] { ',' }, System.StringSplitOptions.RemoveEmptyEntries))
                                        {
                                            selectedValues.Add(val.Trim());
                                        }
                                    }
                                    LoggingService.Info($"Syncing {pvm.CheckableItems.Count} CheckableItems for '{pvm.Name}' from string: '{savedStr}'", component: "MainWindowViewModel");
                                }
                                
                                foreach (var item in pvm.CheckableItems)
                                {
                                    bool shouldBeChecked = selectedValues.Contains(item.Value);
                                    if (item.IsChecked != shouldBeChecked)
                                    {
                                        LoggingService.Debug($"  - Updating '{item.Value}': {item.IsChecked} → {shouldBeChecked}", component: "MainWindowViewModel");
                                        item.IsChecked = shouldBeChecked;
                                    }
                                }
                            }
                            else if (pvm.IsMultiSelect && pvm.IsListBox)
                            {
                                // For ListBox-based multi-select, update SelectedItems collection
                                LoggingService.Debug($"MainWindowViewModel restoring SelectedItems for '{pvm.Name}', current count: {pvm.SelectedItems.Count}", component: "MainWindowViewModel");
                                
                                var selectedValues = new System.Collections.Generic.HashSet<string>(System.StringComparer.OrdinalIgnoreCase);
                                
                                // Handle both array and string formats
                                if (savedValue is System.Array savedArray)
                                {
                                    // Extract values from array
                                    foreach (var item in savedArray)
                                    {
                                        if (item != null && !string.IsNullOrWhiteSpace(item.ToString()))
                                        {
                                            selectedValues.Add(item.ToString().Trim());
                                        }
                                    }
                                    LoggingService.Info($"Syncing SelectedItems for '{pvm.Name}' from array: [{string.Join(",", selectedValues)}]", component: "MainWindowViewModel");
                                }
                                else
                                {
                                    // Fallback to string parsing
                                    string savedStr = savedValue?.ToString() ?? string.Empty;
                                    if (!string.IsNullOrEmpty(savedStr))
                                    {
                                        foreach (var val in savedStr.Split(new[] { ',' }, System.StringSplitOptions.RemoveEmptyEntries))
                                        {
                                            selectedValues.Add(val.Trim());
                                        }
                                    }
                                    LoggingService.Info($"Syncing SelectedItems for '{pvm.Name}' from string: '{savedStr}'", component: "MainWindowViewModel");
                                }
                                
                                // Update SelectedItems collection to match saved values
                                pvm.SelectedItems.Clear();
                                foreach (var value in selectedValues)
                                {
                                    pvm.SelectedItems.Add(value);
                                    LoggingService.Debug($"  - Added to SelectedItems: '{value}'", component: "MainWindowViewModel");
                                }
                                LoggingService.Debug($"After restoration, SelectedItems count is: {pvm.SelectedItems.Count}", component: "MainWindowViewModel");
                            }
                            else
                            {
                                pvm.Value = savedValue?.ToString();
                            }
                        }
                    }
                }
                
                UpdateNavigationButtonVisibility();
                UpdateCurrentStepValidation();
                LoggingService.Trace("<<< UpdateCurrentPage END (used cache)", component: "MainWindowViewModel");
                return;
            }

            LoggingService.Info($"Creating NEW page for index {_currentPageIndex} ('{currentStepInfo?.Title}')", component: "MainWindowViewModel");

            object newPage = null; // Variable to hold the created page

            if (currentStepInfo.PageType == "GenericForm")
            {
                LoggingService.Trace($"  - Creating GenericFormViewModel for step \'{currentStepInfo.Title}\'", component: "MainWindowViewModel");
                var formViewModel = new GenericFormViewModel(
                    currentStepInfo.Title ?? $"Step {_currentPageIndex + 1}", 
                    currentStepInfo.Description)
                {
                    Parameters = new ObservableCollection<ParameterViewModel>()
                };

                if (currentStepInfo.Parameters != null)
                {
                    LoggingService.Trace($"    - Processing {currentStepInfo.Parameters.Count} parameters for GenericFormViewModel", component: "MainWindowViewModel");
                    int paramIndex = 0;
                    foreach (var paramInfo in currentStepInfo.Parameters)
                    {
                        LoggingService.Trace($"      - Parameter {paramIndex}: Name=\'{paramInfo.Name}\', Type=\'{paramInfo.ParameterType?.Name ?? "null"}\'", component: "MainWindowViewModel");
                        
                        // Check if this parameter is a card
                        if (!string.IsNullOrEmpty(paramInfo.CardTitle) && !string.IsNullOrEmpty(paramInfo.CardContent))
                        {
                            LoggingService.Trace($"        - Creating card: {paramInfo.CardTitle}", component: "MainWindowViewModel");
                            formViewModel.AdditionalCards.Add(new CardViewModel
                            {
                                Title = paramInfo.CardTitle,
                                Content = paramInfo.CardContent
                            });
                            paramIndex++;
                            continue; // Skip adding as a parameter control
                        }
                        
                        // Skip placeholder parameters (they don't render as controls)
                        if (paramInfo.IsPlaceholder)
                        {
                            LoggingService.Trace($"        - Skipping placeholder parameter: {paramInfo.Name}", component: "MainWindowViewModel");
                            paramIndex++;
                            continue;
                        }
                        
                        // Add regular parameter control
                        LoggingService.Trace($"        - Creating ParameterViewModel for: {paramInfo.Name}", component: "MainWindowViewModel");
                        
                        object existingValue = null;
                        if (FormData.TryGetValue(paramInfo.Name, out object savedValue))
                        {
                            existingValue = savedValue;
                            LoggingService.Trace($"        - Found existing value for \'{paramInfo.Name}\' in FormData: \'{existingValue}\' (Type: {existingValue?.GetType().Name ?? "null"})", component: "MainWindowViewModel");
                        }
                        else
                        {
                             LoggingService.Trace($"        - No existing value found for \'{paramInfo.Name}\' in FormData.", component: "MainWindowViewModel");
                        }
                        
                        try
                        {
                            var paramVm = new ParameterViewModel(paramInfo, this, existingValue, _dialogService);
                            formViewModel.Parameters.Add(paramVm);
                            
                            // Track for dynamic parameter updates (Phase 2)
                            if (_parameterViewModels != null && !string.IsNullOrEmpty(paramInfo.Name))
                            {
                                _parameterViewModels[paramInfo.Name] = paramVm;
                                // Note: Initial data is loaded in ReflectionService pre-execution
                                // RefreshParameterChoices is called when dependencies change
                            }
                            
                            LoggingService.Trace($"        - Successfully added ParameterViewModel {paramIndex} ('{paramInfo.Name}')", component: "MainWindowViewModel");
                        }
                        catch(Exception pvmEx)
                        {
                            LoggingService.Error("Failed to create or add ParameterViewModel", pvmEx, "MainWindowViewModel");
                            // Optionally, add a placeholder or error indicator to the UI if needed
                        }
                        paramIndex++; // Increment index regardless of success/failure to match count
                    }
                    LoggingService.Trace($"    - Finished processing {paramIndex} parameters for GenericFormViewModel", component: "MainWindowViewModel"); 
                }
                else
                {
                     LoggingService.Trace($"    - No parameters defined for this GenericForm step.", component: "MainWindowViewModel");
                }
                newPage = formViewModel; // Assign the created form
            }
            else if (currentStepInfo.PageType == "Card")
            {
                LoggingService.Trace("  - Creating CardViewModel", component: "MainWindowViewModel");
                
                // Create a form view model to hold parameters and display form controls
                var formViewModel = new GenericFormViewModel(currentStepInfo.Title ?? "Information", currentStepInfo.Description ?? "");
                
                // Create and add the main card
                var mainCard = new CardViewModel
                {
                    Title = currentStepInfo.Title ?? "Information",
                    Content = currentStepInfo.Description ?? "This is a card for displaying informational text."
                };
                formViewModel.Parameters = new ObservableCollection<ParameterViewModel>();
                
                // Process parameters for this step
                if (currentStepInfo.Parameters != null)
                {
                    LoggingService.Trace($"Processing {currentStepInfo.Parameters.Count} parameters for Card step", component: "MainWindowViewModel");
                    
                    // First process additional card controls
                    foreach (var paramInfo in currentStepInfo.Parameters)
                    {
                        // If this parameter has card properties, create a CardViewModel for it
                        if (!string.IsNullOrEmpty(paramInfo.CardTitle) && !string.IsNullOrEmpty(paramInfo.CardContent))
                        {
                            LoggingService.Trace($"Creating additional card: {paramInfo.CardTitle}", component: "MainWindowViewModel");
                            formViewModel.AdditionalCards.Add(new CardViewModel
                            {
                                Title = paramInfo.CardTitle,
                                Content = paramInfo.CardContent
                            });
                        }
                        // Otherwise, if it's a regular parameter (not a placeholder), add it to the form
                        else if (paramInfo.ParameterType != null && 
                                 !paramInfo.IsPlaceholder && 
                                 !string.IsNullOrEmpty(paramInfo.Label))
                        {
                            LoggingService.Trace($"Adding parameter control to Card step: {paramInfo.Name}", component: "MainWindowViewModel");
                            
                            object existingValue = null;
                            if (FormData.TryGetValue(paramInfo.Name, out object savedValue))
                            {
                                existingValue = savedValue;
                            }
                            
                            var paramVm = new ParameterViewModel(paramInfo, this, existingValue, _dialogService);
                            formViewModel.Parameters.Add(paramVm);
                            
                            // Track for dynamic parameter updates (Phase 2)
                            if (_parameterViewModels != null && !string.IsNullOrEmpty(paramInfo.Name))
                            {
                                _parameterViewModels[paramInfo.Name] = paramVm;
                            }
                        }
                    }
                }
                
                // Set the completed form view model as the current page
                newPage = formViewModel;
                
                // Also add the main card as the first card
                formViewModel.AdditionalCards.Insert(0, mainCard);
            }
            else
            {
                LoggingService.Warn($"Unknown PageType encountered: '{currentStepInfo.PageType}' for step '{currentStepInfo.Title}'", component: "MainWindowViewModel");
                newPage = new ErrorViewModel($"Unknown page type '{currentStepInfo.PageType}' encountered.");
            }

            // --- ADDED Logging around CurrentPage assignment ---
            var previousPageType = CurrentPage?.GetType().Name ?? "null";
            
            // Cache the page for reuse on navigation
            if (newPage != null)
            {
                _pageCache[_currentPageIndex] = newPage;
                LoggingService.Info($"Cached page at index {_currentPageIndex}", component: "MainWindowViewModel");
            }
            
            CurrentPage = newPage;
            var newPageType = CurrentPage?.GetType().Name ?? "null";
            LoggingService.Info($"===> CurrentPage set. Index: {_currentPageIndex}. Previous Type: {previousPageType}, New Type: {newPageType}. Is Null: {CurrentPage == null}", component: "MainWindowViewModel");
            // --- END Logging --- 
            
            UpdateNavigationButtonVisibility();
            
            // Update validation status for the current page
            UpdateCurrentStepValidation();
            
            LoggingService.Trace("<<< UpdateCurrentPage END", component: "MainWindowViewModel"); 
        }

        private bool CanExecuteNext(object parameter)
        {
            bool canExecute = CurrentStep <= Steps.Count && !(CurrentPage is ErrorViewModel);

            if (canExecute)
            {
                // If on execution console, allow close when not running
                if (CurrentPage is ExecutionConsoleViewModel consoleVm)
                {
                    canExecute = !consoleVm.IsRunning;
                }
                // For all other steps, allow navigation without validation
                // Validation will only happen on final step when clicking Finish
            }

            return canExecute;
        }
        
        private bool CanExecutePrevious(object parameter) => CanGoBack;

        private void ExecuteNext(object parameter)
        {
            try
            {
                LoggingService.Info($"ExecuteNext called with parameter: {parameter}, CurrentPage: {CurrentPage?.GetType().Name}", component: "MainWindowViewModel");
                LoggingService.Info("ExecuteNext called", component: "MainWindowViewModel");
                LoggingService.LogUI($"Next button clicked, CurrentStep: {CurrentStep}", "MainWindowViewModel");

                // For regular steps, allow navigation without validation
                if (CurrentStep < Steps.Count)
                {
                    LoggingService.Info($"ExecuteNext: Taking navigation branch (CurrentStep={CurrentStep} < Steps.Count={Steps.Count})", component: "MainWindowViewModel");
                    if (CurrentPage is ErrorViewModel)
                    {
                        LoggingService.Debug("Cannot proceed from error page.", component: "MainWindowViewModel");
                        LoggingService.LogUI("Navigation blocked - on error page", "MainWindowViewModel");
                        return;
                    }

                    SaveCurrentPageData();
                    
                    // Mark current step as completed when navigating forward
                    if (CurrentStep > 0 && CurrentStep <= Steps.Count)
                    {
                        var currentStepItem = Steps[CurrentStep - 1];
                        
                        // Check if all mandatory fields in this step are filled
                        bool allMandatoryFilled = true;
                        if (_wizardSteps != null && CurrentStep <= _wizardSteps.Count)
                        {
                            var stepInfo = _wizardSteps[CurrentStep - 1];
                            if (stepInfo.Parameters != null)
                            {
                                foreach (var param in stepInfo.Parameters)
                                {
                                    if (param.IsMandatory)
                                    {
                                        if (!FormData.TryGetValue(param.Name, out object value) || 
                                            (value == null || string.IsNullOrWhiteSpace(value.ToString())))
                                        {
                                            allMandatoryFilled = false;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        
                        if (allMandatoryFilled)
                        {
                            currentStepItem.IsCompleted = true;
                            currentStepItem.IsValid = true;
                            LoggingService.Info($"Step '{currentStepItem.Title}' marked as completed and valid", component: "MainWindowViewModel");
                        }
                        else
                        {
                            currentStepItem.IsCompleted = false;
                            currentStepItem.IsValid = false;
                            LoggingService.Warn($"Step '{currentStepItem.Title}' has incomplete mandatory fields", component: "MainWindowViewModel");
                        }
                    }
                    
                    CurrentStep++;
                    LoggingService.Info($"Navigated to next step: {CurrentStep}", component: "MainWindowViewModel");
                    LoggingService.LogUI($"Navigation successful - moved to step {CurrentStep}", "MainWindowViewModel");
                }
                else if (CurrentPage is ExecutionConsoleViewModel)
                {
                    LoggingService.Info("ExecuteNext: Detected ExecutionConsoleViewModel, calling SerializeFormDataToJson", component: "MainWindowViewModel");
                    // Serialize FormData to JSON before closing
                    SerializeFormDataToJson();
                    LoggingService.Info("ExecuteNext: SerializeFormDataToJson completed, closing window", component: "MainWindowViewModel");
                    // Close the application when on execution console
                    Application.Current.MainWindow?.Close();
                }
                else
                {
                    LoggingService.Info($"ExecuteNext: Taking final execution branch (CurrentStep={CurrentStep}, Steps.Count={Steps.Count})", component: "MainWindowViewModel");
                    // Final step - run comprehensive validation before execution
                    
                    SaveCurrentPageData();
                    
                    LoggingService.Info("Final step - validating all parameters before execution", component: "MainWindowViewModel");
                    
                    string summary;
                    if (!CollectAllValidationErrors(out summary))
                    {
                        LoggingService.Warn("Pre-execution validation failed; blocking execution.", component: "MainWindowViewModel");
                        
                        // Show detailed validation popup
                        System.Windows.MessageBox.Show(
                            $"Please complete the following required fields before continuing:\n\n{summary}",
                            "Required Fields Missing",
                            System.Windows.MessageBoxButton.OK,
                            System.Windows.MessageBoxImage.Warning);
                        
                        return;
                    }
                    
                    // All validation passed - execute script
                    RunScript();
                }
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in ExecuteNext", ex, "MainWindowViewModel");
                System.Windows.MessageBox.Show($"An error occurred: {ex.Message}", "Error", System.Windows.MessageBoxButton.OK, System.Windows.MessageBoxImage.Error);
            }
        }

        private void ExecutePrevious(object parameter)
        {
            try
            {
                LoggingService.Info("ExecutePrevious called", component: "MainWindowViewModel");

                // Allow navigating back without blocking on current page validation
                SaveCurrentPageData();

                if (CurrentStep > 1)
                {
                    CurrentStep--;
                    LoggingService.Info($"Navigated to previous step: {CurrentStep}", component: "MainWindowViewModel");
                }
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in ExecutePrevious", ex, "MainWindowViewModel");
            }
        }

        private void ExecuteLoadScript(object parameter)
        {
            string path = parameter as string;
            if (!string.IsNullOrEmpty(path))
            {
                LoadScript(path);
            }
            else
            {
                LoggingService.Warn("ExecuteLoadScript called with null or empty parameter.", component: "MainWindowViewModel");
            }
        }

        /// <summary>
        /// Initialize dynamic parameter management (Phase 2)
        /// </summary>
        private void InitializeDynamicParameters()
        {
            LoggingService.Info("Initializing dynamic parameters (Phase 2)", component: "MainWindowViewModel");
            
            // Create runspace for dynamic parameter execution
            _dynamicParameterRunspace = RunspaceFactory.CreateRunspace();
            _dynamicParameterRunspace.Open();
            _dynamicParameterManager = new DynamicParameterManager(_dynamicParameterRunspace);
            
            // Build maps
            _dynamicParametersMap = new Dictionary<string, ParameterInfo>(StringComparer.OrdinalIgnoreCase);
            _parameterViewModels = new Dictionary<string, ParameterViewModel>(StringComparer.OrdinalIgnoreCase);
            
            // Find all dynamic parameters and register them
            if (_wizardSteps == null) return;
            
            foreach (var step in _wizardSteps)
            {
                foreach (var param in step.Parameters)
                {
                    if (param.IsDynamic)
                    {
                        _dynamicParametersMap[param.Name] = param;
                        
                        // Register with DynamicParameterManager
                        var attr = new WizardDataSourceAttribute();
                        
                        if (!string.IsNullOrEmpty(param.DataSourceScriptBlock))
                        {
                            attr.ScriptBlock = ScriptBlock.Create(param.DataSourceScriptBlock);
                        }
                        else if (!string.IsNullOrEmpty(param.DataSourceCsvPath))
                        {
                            attr.CsvPath = param.DataSourceCsvPath;
                            attr.CsvColumn = param.DataSourceCsvColumn;
                            if (!string.IsNullOrEmpty(param.DataSourceCsvFilter))
                            {
                                attr.CsvFilter = ScriptBlock.Create(param.DataSourceCsvFilter);
                            }
                        }
                        
                        attr.DependsOn = param.DataSourceDependsOn?.ToArray() ?? new string[0];
                        attr.Async = param.DataSourceAsync;
                        attr.ShowRefreshButton = param.DataSourceShowRefresh;
                        
                        _dynamicParameterManager.RegisterParameter(param.Name, attr);
                        
                        LoggingService.Info($"  Registered dynamic parameter: {param.Name}, Dependencies: [{string.Join(", ", attr.DependsOn)}]", component: "MainWindowViewModel");
                    }
                }
            }
            
            LoggingService.Info($"Dynamic parameters initialized: {_dynamicParametersMap.Count} dynamic parameters registered", component: "MainWindowViewModel");
        }
        
        /// <summary>
        /// Handle parameter value changes and refresh dependent parameters (Phase 2)
        /// </summary>
        private async void RefreshDependentParameters(string changedParameterName)
        {
            if (_dynamicParameterManager == null || _dynamicParametersMap == null)
                return;
                
            LoggingService.Debug($"Checking for parameters dependent on '{changedParameterName}'", component: "MainWindowViewModel");
            
            // Find all parameters that depend on the changed parameter
            var dependentParams = _dynamicParametersMap.Values
                .Where(p => p.DataSourceDependsOn != null && 
                           p.DataSourceDependsOn.Contains(changedParameterName, StringComparer.OrdinalIgnoreCase))
                .ToList();
            
            if (!dependentParams.Any())
            {
                LoggingService.Trace($"  No dependent parameters found for '{changedParameterName}'", component: "MainWindowViewModel");
                return;
            }
            
            LoggingService.Info($"Found {dependentParams.Count} parameters dependent on '{changedParameterName}': [{string.Join(", ", dependentParams.Select(p => p.Name))}]", component: "MainWindowViewModel");
            
            // Re-execute each dependent parameter's data source SEQUENTIALLY to avoid runspace conflicts
            foreach (var dependentParam in dependentParams)
            {
                await RefreshParameterChoicesAsync(dependentParam.Name);
            }
        }
        
        /// <summary>
        /// Core method to refresh parameter choices (Phase 2)
        /// </summary>
        private async Task RefreshParameterChoicesAsync(string parameterName)
        {
            if (_dynamicParameterManager == null || _dynamicParametersMap == null)
                return;
                
            if (!_dynamicParametersMap.TryGetValue(parameterName, out var paramInfo))
            {
                LoggingService.Warn($"Parameter '{parameterName}' not found in dynamic parameters map", component: "MainWindowViewModel");
                return;
            }
            
            if (!_parameterViewModels.TryGetValue(parameterName, out var paramVm))
            {
                LoggingService.Warn($"ParameterViewModel for '{parameterName}' not found", component: "MainWindowViewModel");
                return;
            }
            
            try
            {
                LoggingService.Info($"  Refreshing parameter: {parameterName}", component: "MainWindowViewModel");
                
                // Get current form values for passing to data source
                var currentValues = new Dictionary<string, object>(FormData, StringComparer.OrdinalIgnoreCase);
                
                // Log dependency values
                if (paramInfo.DataSourceDependsOn != null && paramInfo.DataSourceDependsOn.Any())
                {
                    var depValues = string.Join(", ", paramInfo.DataSourceDependsOn.Select(d => 
                    {
                        object val;
                        return currentValues.TryGetValue(d, out val) ? $"{d}={val}" : $"{d}=NULL";
                    }));
                    LoggingService.Info($"  Parameter '{parameterName}' dependencies: {depValues}", component: "MainWindowViewModel");
                }
                
                // Execute data source with progress indicator
                var newChoices = await ExecuteWithProgress(
                    () => _dynamicParameterManager.ExecuteDataSource(parameterName, currentValues),
                    $"Loading {paramInfo.Label ?? parameterName}...");
                
                // Update the parameter's choices
                if (newChoices != null && newChoices.Length > 0)
                {
                    paramInfo.ValidateSetChoices = newChoices.ToList();
                    LoggingService.Info($"    Updated choices for '{parameterName}': {newChoices.Length} items", component: "MainWindowViewModel");
                    
                    // Update the UI
                    Application.Current.Dispatcher.Invoke(() =>
                    {
                        paramVm.Choices.Clear();
                        foreach (var choice in newChoices)
                        {
                            paramVm.Choices.Add(choice);
                        }
                        LoggingService.Debug($"    UI updated: {parameterName} now has {paramVm.Choices.Count} choices", component: "MainWindowViewModel");
                    });
                }
                else
                {
                    LoggingService.Warn($"    No choices returned for '{parameterName}'", component: "MainWindowViewModel");
                }
            }
            catch (Exception ex)
            {
                LoggingService.Error($"Failed to refresh parameter '{parameterName}': {ex.Message}", component: "MainWindowViewModel");
            }
        }

        protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
        {
            // --- ADDED Logging for CurrentPage specifically ---
            if (propertyName == nameof(CurrentPage))
            {
                LoggingService.Debug($"--> OnPropertyChanged triggered for CurrentPage. New type: {CurrentPage?.GetType().Name ?? "null"}", component: "MainWindowViewModel");
            }
            // --- END Logging ---
            
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
            LogViewModelState(); // Keep this call if it provides useful general state logging
        }

        /// <summary>
        /// Executes an async operation with progress indicator if it exceeds the threshold.
        /// Shows progress overlay only for operations that take longer than ProgressThresholdMs.
        /// </summary>
        /// <typeparam name="T">Return type of the operation</typeparam>
        /// <param name="operation">The async operation to execute</param>
        /// <param name="message">Progress message to display</param>
        /// <param name="thresholdMs">Minimum duration before showing progress (default: 500ms)</param>
        /// <returns>Result of the operation</returns>
        protected async Task<T> ExecuteWithProgress<T>(Func<Task<T>> operation, string message, int? thresholdMs = null)
        {
            var threshold = thresholdMs ?? 500;
            var stopwatch = Stopwatch.StartNew();
            bool showedProgress = false;

            try
            {
                // Start the operation
                var operationTask = operation();

                // Wait for threshold or completion
                var delayTask = Task.Delay(threshold);
                var completedTask = await Task.WhenAny(operationTask, delayTask);

                // If operation completed within threshold, return immediately
                if (completedTask == operationTask)
                {
                    stopwatch.Stop();
                    if (_dynamicParameterManager?.ExecutionOptions?.EnablePerformanceLogging == true)
                    {
                        LoggingService.Debug($"Operation '{message}' completed in {stopwatch.ElapsedMilliseconds}ms (fast path)", component: "MainWindowViewModel");
                    }
                    return await operationTask;
                }

                // Operation is slow, show progress
                showedProgress = true;
                ProcessingMessage = message;
                IsProcessing = true;

                LoggingService.Debug($"Operation '{message}' exceeded {threshold}ms threshold, showing progress indicator", component: "MainWindowViewModel");

                // Wait for operation to complete
                var result = await operationTask;

                stopwatch.Stop();
                if (_dynamicParameterManager?.ExecutionOptions?.EnablePerformanceLogging == true)
                {
                    LoggingService.Debug($"Operation '{message}' completed in {stopwatch.ElapsedMilliseconds}ms (slow path)", component: "MainWindowViewModel");
                }

                return result;
            }
            finally
            {
                if (showedProgress)
                {
                    IsProcessing = false;
                }
            }
        }

        /// <summary>
        /// Executes a sync operation with progress indicator if it exceeds the threshold.
        /// </summary>
        protected async Task<T> ExecuteWithProgress<T>(Func<T> operation, string message, int? thresholdMs = null)
        {
            return await ExecuteWithProgress(() => Task.Run(operation), message, thresholdMs);
        }
        
        private void RunScript()
        {
            LoggingService.Debug("!!! RunScript method entered !!!!", component: "MainWindowViewModel");
            try
            {
                LoggingService.Info("RunScript called. Preparing to execute script.", component: "MainWindowViewModel");
                LoggingService.Info($"Script Path: {ScriptPath}", component: "MainWindowViewModel");
                LoggingService.LogCommand($"Script execution starting: {ScriptPath}", "MainWindowViewModel");
                
                // Final security check: Verify script hash hasn't changed since load
                if (!string.IsNullOrEmpty(_scriptHash))
                {
                    string currentHash = SecurityValidator.ComputeFileHash(ScriptPath);
                    if (!string.Equals(_scriptHash, currentHash, StringComparison.OrdinalIgnoreCase))
                    {
                        string errorMsg = "Script file was modified after load. Execution blocked for security.";
                        AuditLogger.LogSecurityViolation("Script Modified Before Execution", 
                            $"File: {ScriptPath}\nOriginal Hash: {_scriptHash}\nCurrent Hash: {currentHash}");
                        LoggingService.Error(errorMsg, component: "MainWindowViewModel");
                        CurrentPage = new ErrorViewModel(errorMsg);
                        return;
                    }
                }
                
                // Log execution start to audit log
                _scriptExecutionStartTime = DateTime.UtcNow;
                AuditLogger.LogScriptExecutionStart(ScriptPath);

                // 1) Prepare console page and logs
                // Priority for log filename:
                // 1. OriginalScriptName from branding (for Module API scripts)
                // 2. Script filename (for parameter-based scripts)
                // 3. WindowTitle (fallback)
                string logBaseName = null;
                
                // Check for OriginalScriptName in branding (Module API scripts)
                string originalScriptDirectory = null;

                if (_parsedData?.Branding != null && !string.IsNullOrWhiteSpace(_parsedData.Branding.OriginalScriptName))
                {
                    logBaseName = _parsedData.Branding.OriginalScriptName;
                    LoggingService.Info($"Using OriginalScriptName from branding for log: {logBaseName}", component: "MainWindowViewModel");
                    if (!string.IsNullOrWhiteSpace(_parsedData.Branding.OriginalScriptPath))
                    {
                        originalScriptDirectory = _parsedData.Branding.OriginalScriptPath;
                        LoggingService.Info($"Using OriginalScriptPath from branding: {originalScriptDirectory}", component: "MainWindowViewModel");
                    }
                }
                
                // Fallback to script filename (parameter-based scripts)
                if (string.IsNullOrWhiteSpace(logBaseName))
                {
                    logBaseName = System.IO.Path.GetFileNameWithoutExtension(ScriptPath);
                }
                
                // Sanitize for filename use
                foreach (char c in System.IO.Path.GetInvalidFileNameChars())
                {
                    logBaseName = logBaseName.Replace(c, '_');
                }
                logBaseName = logBaseName.Replace(':', '-').Replace(' ', '_');
                
                // Add timestamp with full precision: yyyy-MM-dd_HHmmss
                string ts = DateTime.Now.ToString("yyyy-MM-dd_HHmmss");
                string logsDir;
                if (!string.IsNullOrWhiteSpace(originalScriptDirectory))
                {
                    try
                    {
                        logsDir = System.IO.Path.Combine(originalScriptDirectory, "logs");
                        if (!Directory.Exists(logsDir)) Directory.CreateDirectory(logsDir);
                    }
                    catch (Exception ex)
                    {
                        LoggingService.Warn($"Failed to use script directory for logs ({originalScriptDirectory}). Falling back to executable logs directory. {ex.Message}", component: "MainWindowViewModel");
                        logsDir = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                        if (!Directory.Exists(logsDir)) Directory.CreateDirectory(logsDir);
                    }
                }
                else
                {
                    logsDir = System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                    if (!Directory.Exists(logsDir)) Directory.CreateDirectory(logsDir);
                }
                LoggingService.Info($"Per-execution log directory: {logsDir}", component: "MainWindowViewModel");
                _structuredLogPath = System.IO.Path.Combine(logsDir, $"{logBaseName}.{ts}.log");

                _consoleVm = new ExecutionConsoleViewModel(onCancel: StopCurrentExecution, closeCommand: NextCommand)
                {
                    LogFilePath = _structuredLogPath,
                    StatusText = "Running...",
                    
                };
                CurrentPage = _consoleVm;
                NextButtonText = "Close"; // Final page behavior
                CanGoBack = false;

                // Open structured log writer
                _structuredLogWriter = new System.IO.StreamWriter(_structuredLogPath, append: true, Encoding.UTF8) { AutoFlush = true };
                WriteHeaderLine("SESSION START");

                // 2) Read and preprocess script
                string originalScriptContent = File.ReadAllText(ScriptPath);
                string processedScriptContent = PreProcessScriptForExecution(originalScriptContent);
                if (processedScriptContent == null)
                {
                    AppendLine("ERR", "Failed to pre-process script content.");
                    CurrentPage = new ErrorViewModel("Failed to prepare script for execution.");
                    return;
                }

                // 3) Create runspace/PowerShell with security constraints
                // Use Full Language Mode with custom security validation
                InitialSessionState iss = InitialSessionState.CreateDefault();
                iss.LanguageMode = PSLanguageMode.FullLanguage;
                
                // Security validation is performed via Test-ScriptSecurity before execution
                LoggingService.Info("Script will execute with custom security validation", component: "MainWindowViewModel");
                AuditLogger.LogScriptExecutionStart(ScriptPath);
                
                _currentRunspace = RunspaceFactory.CreateRunspace(iss);
                _currentRunspace.Open();
                _currentPowerShell = PowerShell.Create();
                _currentPowerShell.Runspace = _currentRunspace;

                // Set preferences
                _currentPowerShell.AddScript("$InformationPreference='Continue'; $VerbosePreference='Continue'; $DebugPreference='Continue';");
                // Add main script
                _currentPowerShell.AddScript(processedScriptContent, useLocalScope: false);

                // Add parameters to the last command (script)
                LoggingService.Debug("Adding parameters to PowerShell command:", component: "MainWindowViewModel");
                if (FormData != null && FormData.Any())
                {
                    foreach (var kvp in FormData)
                    {
                        var paramDef = _parsedData?.WizardSteps
                            .SelectMany(s => s.Parameters ?? Enumerable.Empty<ParameterInfo>())
                            .FirstOrDefault(p => p?.Name == kvp.Key);
                        
                        // Skip placeholder parameters that aren't actual data
                        if (paramDef?.IsPlaceholder == true)
                        {
                            LoggingService.Trace($"  Skipping placeholder parameter: {kvp.Key}", component: "MainWindowViewModel");
                            continue;
                        }

                        if (paramDef == null)
                        {
                            _currentPowerShell.AddParameter(kvp.Key, kvp.Value);
                            continue;
                        }

                        // Security: Never log sensitive values
                        bool isSensitive = paramDef.ParameterType == typeof(SecureString) || 
                                          kvp.Key.ToLower().Contains("password") || 
                                          kvp.Key.ToLower().Contains("credential");
                        
                        if (!isSensitive && kvp.Value != null)
                        {
                            string valueDisplay = kvp.Value is Array arr ? 
                                $"Array[{arr.Length}]: [{string.Join(",", arr.Cast<object>())}]" : 
                                kvp.Value.ToString();
                            LoggingService.Info($"  Parameter '{kvp.Key}' = '{valueDisplay}' (Type: {kvp.Value.GetType().Name}, IsSwitch: {paramDef.IsSwitch}, ParamType: {paramDef.ParameterType?.Name})", component: "MainWindowViewModel");
                        }

                        // Skip optional parameters with empty/null values - let PowerShell use defaults
                        if (!paramDef.IsMandatory)
                        {
                            bool isEmpty = false;
                            
                            if (paramDef.ParameterType == typeof(SecureString))
                            {
                                var secureVal = kvp.Value as SecureString;
                                isEmpty = (secureVal == null || secureVal.Length == 0);
                            }
                            else if (paramDef.ParameterType == typeof(bool) || paramDef.IsSwitch)
                            {
                                // Booleans and switches always have a value (true/false)
                                isEmpty = false;
                            }
                            else
                            {
                                // For other types (string, int, etc.), check if empty
                                isEmpty = (kvp.Value == null || string.IsNullOrWhiteSpace(kvp.Value.ToString()));
                            }
                            
                            if (isEmpty)
                            {
                                LoggingService.Debug($"Skipping empty optional parameter '{kvp.Key}' - will use script default", component: "MainWindowViewModel");
                                continue;
                            }
                        }

                        // Handle switches
                        try
                        {
                            if (paramDef.IsSwitch)
                            {
                                // Convert value to bool if needed
                                bool switchValue = false;
                                if (kvp.Value is bool bv)
                                {
                                    switchValue = bv;
                                }
                                else if (kvp.Value != null)
                                {
                                    bool.TryParse(kvp.Value.ToString(), out switchValue);
                                }
                                
                                // Only add switch parameter if true (PowerShell convention)
                                if (switchValue)
                                {
                                    _currentPowerShell.AddParameter(kvp.Key);
                                }
                            }
                            else if (paramDef.ParameterType == typeof(bool))
                            {
                                bool b = false; 
                                if (kvp.Value is bool db) 
                                    b = db; 
                                else if (kvp.Value != null) 
                                    bool.TryParse(kvp.Value.ToString(), out b);
                                _currentPowerShell.AddParameter(kvp.Key, b);
                            }
                            else
                            {
                                _currentPowerShell.AddParameter(kvp.Key, kvp.Value);
                            }
                        }
                        catch (Exception paramEx)
                        {
                            LoggingService.Error($"Failed to add parameter '{kvp.Key}': {paramEx.Message}", paramEx, component: "MainWindowViewModel");
                            AppendLine("ERR", $"Parameter error: {kvp.Key} - {paramEx.Message}");
                            throw; // Re-throw to fail execution
                        }
                    }
                }

                // No raw transcript; nothing to stop

                // Subscribe to streams
                _currentPowerShell.Streams.Information.DataAdded += (s, e) =>
                {
                    try
                    {
                        var rec = _currentPowerShell.Streams.Information[e.Index];
                        var msg = rec?.MessageData?.ToString() ?? rec?.ToString() ?? string.Empty;
                        AppendLine("HOST", msg);
                    }
                    catch { }
                };
                _currentPowerShell.Streams.Warning.DataAdded += (s, e) =>
                {
                    try
                    {
                        var msg = _currentPowerShell.Streams.Warning[e.Index].ToString();
                        AppendLine("WARN", msg);
                        LoggingService.LogCommand($"Warning: {msg}", "PowerShell");
                    }
                    catch { }
                };
                _currentPowerShell.Streams.Error.DataAdded += (s, e) =>
                {
                    try
                    {
                        var msg = _currentPowerShell.Streams.Error[e.Index].ToString();
                        AppendLine("ERR", msg);
                        LoggingService.LogCommand($"Error: {msg}", "PowerShell");
                    }
                    catch { }
                };
                _currentPowerShell.Streams.Verbose.DataAdded += (s, e) =>
                {
                    try
                    {
                        var msg = _currentPowerShell.Streams.Verbose[e.Index].ToString();
                        AppendLine("VERBOSE", msg);
                        LoggingService.LogCommand($"Verbose: {msg}", "PowerShell");
                    }
                    catch { }
                };
                _currentPowerShell.Streams.Debug.DataAdded += (s, e) =>
                {
                    try
                    {
                        var msg = _currentPowerShell.Streams.Debug[e.Index].ToString();
                        AppendLine("DEBUG", msg);
                        LoggingService.LogCommand($"Debug: {msg}", "PowerShell");
                    }
                    catch { }
                };
                _currentPowerShell.Streams.Progress.DataAdded += (s, e) =>
                {
                    try
                    {
                        var msg = _currentPowerShell.Streams.Progress[e.Index].ToString();
                        AppendLine("PROGRESS", msg);
                        LoggingService.LogCommand($"Progress: {msg}", "PowerShell");
                    }
                    catch { }
                };

                // Setup state change handler
                _currentPowerShell.InvocationStateChanged += (s, e) =>
                {
                    AppendLine("INFO", $"PowerShell state changed to: {e.InvocationStateInfo.State}");
                    
                    if (e.InvocationStateInfo.State == PSInvocationState.Completed)
                    {
                        if (_currentPowerShell.Streams.Error.Count > 0)
                        {
                            LoggingService.Warn($"PowerShell execution completed with {_currentPowerShell.Streams.Error.Count} errors", component: "MainWindowViewModel");
                            LoggingService.LogCommand($"Execution completed with {_currentPowerShell.Streams.Error.Count} errors", "MainWindowViewModel");
                            
                            // Log all errors to file
                            foreach (var error in _currentPowerShell.Streams.Error)
                            {
                                var errorMsg = error.ToString();
                                AppendLine("ERR", errorMsg);
                                LoggingService.Error($"PowerShell Error: {errorMsg}", component: "MainWindowViewModel");
                            }
                            
                            WriteHeaderLine($"EXECUTION COMPLETED WITH {_currentPowerShell.Streams.Error.Count} ERRORS");
                            OnExecutionFinished("Failed");
                        }
                        else
                        {
                            LoggingService.Info("PowerShell execution completed successfully", component: "MainWindowViewModel");
                            LoggingService.LogCommand("Execution completed successfully", "MainWindowViewModel");
                            WriteHeaderLine("EXECUTION COMPLETED SUCCESSFULLY");
                            OnExecutionFinished("Completed");
                        }
                    }
                    else if (e.InvocationStateInfo.State == PSInvocationState.Failed)
                    {
                        AppendLine("ERR", $"PowerShell failed. Reason: {e.InvocationStateInfo.Reason?.Message ?? "Unknown"}");
                        if (e.InvocationStateInfo.Reason != null)
                        {
                            AppendLine("ERR", $"Exception: {e.InvocationStateInfo.Reason}");
                        }
                        var err = string.Join(Environment.NewLine, _currentPowerShell.Streams.Error.Select(er => er.ToString()));
                        if (!string.IsNullOrWhiteSpace(err)) AppendLine("ERR", err);
                        OnExecutionFinished("Failed");
                    }
                    else if (e.InvocationStateInfo.State == PSInvocationState.Stopped)
                    {
                        OnExecutionFinished("Canceled");
                    }
                };

                // 4) Begin async invoke
                var output = new PSDataCollection<PSObject>();
                output.DataAdded += (s, e) =>
                {
                    try
                    {
                        var result = output[e.Index];
                        if (result != null)
                        {
                            AppendLine("OUT", result.ToString());
                            
                            // Capture results for Module API
                            _executionResults.Add(result.BaseObject);
                        }
                    }
                    catch { }
                };
                _currentPowerShell.BeginInvoke<PSObject, PSObject>(input: null, output: output);
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in RunScript", ex, "MainWindowViewModel");
                AuditLogger.LogExecutionError(ScriptPath, ex);
                AppendLine("ERR", ex.Message);
                
                // Ensure execution state is reset on error
                if (_consoleVm != null)
                {
                    LoggingService.Debug("Resetting IsRunning to false due to exception in RunScript", component: "MainWindowViewModel");
                    _consoleVm.IsRunning = false;
                    _consoleVm.StatusText = "Error";
                }
                
                CurrentPage = new ErrorViewModel("Failed to execute script: " + ex.Message);
                CleanupExecution();
            }
        }

        private void OnExecutionFinished(string status)
        {
            Application.Current?.Dispatcher.BeginInvoke(DispatcherPriority.Background, new Action(() =>
            {
                try
                {
                    LoggingService.Info($"OnExecutionFinished called with status: {status}", component: "MainWindowViewModel");
                    _consoleVm?.MarkCompleted(status);
                    AppendLine("INFO", $"Execution {status}.");
                    
                    // Log execution completion to audit log
                    if (_scriptExecutionStartTime.HasValue)
                    {
                        TimeSpan duration = DateTime.UtcNow - _scriptExecutionStartTime.Value;
                        int exitCode = status == "Completed" ? 0 : (status == "Canceled" ? 2 : 1);
                        AuditLogger.LogScriptExecutionComplete(ScriptPath, exitCode, duration);
                    }
                    
                    // Serialize execution results for Module API
                    if (status == "Completed" && _executionResults.Count > 0)
                    {
                        try
                        {
                            // Use DataContractJsonSerializer (built into .NET Framework)
                            var resultObj = new
                            {
                                Status = status,
                                Output = _executionResults.Select(o => o?.ToString() ?? string.Empty).ToArray()
                            };
                            
                            using (var ms = new System.IO.MemoryStream())
                            {
                                var serializer = new System.Runtime.Serialization.Json.DataContractJsonSerializer(resultObj.GetType());
                                serializer.WriteObject(ms, resultObj);
                                ms.Position = 0;
                                using (var reader = new System.IO.StreamReader(ms))
                                {
                                    LastExecutionResult = reader.ReadToEnd();
                                }
                            }
                            
                            LoggingService.Info("Execution results serialized for Module API", component: "MainWindowViewModel");
                        }
                        catch (Exception ex)
                        {
                            LoggingService.Warn($"Failed to serialize execution results: {ex.Message}", component: "MainWindowViewModel");
                        }
                    }
                    
                    // Ensure IsRunning is reset to false
                    if (_consoleVm != null && _consoleVm.IsRunning)
                    {
                        LoggingService.Debug("Forcing IsRunning to false in OnExecutionFinished", component: "MainWindowViewModel");
                        _consoleVm.IsRunning = false;
                    }
                }
                finally
                {
                    CleanupExecution();
                }
            }));
        }

        private void StopCurrentExecution()
        {
            try
            {
                _currentPowerShell?.Stop();
            }
            catch { }
        }

        private void WriteHeaderLine(string header)
        {
            lock (_logLock)
            {
                _structuredLogWriter?.WriteLine($"==== {DateTime.Now:yyyy-MM-dd HH:mm:ss} {header} ====");
            }
        }

        private void AppendLine(string level, string message)
        {
            var ts = DateTime.Now;
            Application.Current?.Dispatcher.BeginInvoke(DispatcherPriority.Background, new Action(() =>
            {
                _consoleVm?.AddLine(ts, level, message ?? string.Empty);
            }));

            lock (_logLock)
            {
                _structuredLogWriter?.WriteLine($"[{ts:HH:mm:ss}] [{level}] {message}");
            }
        }

        private void CleanupExecution()
        {
            try
            {
                _structuredLogWriter?.Flush();
                _structuredLogWriter?.Dispose();
            }
            catch { }
            finally { _structuredLogWriter = null; }

            try
            {
                _currentPowerShell?.Dispose();
            }
            catch { }
            finally { _currentPowerShell = null; }

            try
            {
                _currentRunspace?.Close();
                _currentRunspace?.Dispose();
            }
            catch { }
            finally { _currentRunspace = null; }
        }

        private string PreProcessScriptForExecution(string scriptContent)
        {
            try
            {
                // Define known standard parameter attributes (case-insensitive)
                var standardAttributes = new HashSet<string>(StringComparer.OrdinalIgnoreCase) 
                {
                    "Parameter", "ValidateSet", "ValidatePattern", "ValidateScript", 
                    "ValidateRange", "ValidateLength", "ValidateCount", "AllowNull", 
                    "AllowEmptyString", "AllowEmptyCollection", "CmdletBinding", "OutputType"
                    // Add others if needed, but NOT our custom ones (Wizard*)
                };

                // Parse the script into an Abstract Syntax Tree (AST)
                ScriptBlockAst scriptBlockAst = Parser.ParseInput(scriptContent, out _, out ParseError[] errors);

                if (errors.Any())
                {
                    string errorMessages = string.Join("\n", errors.Select(e => $"L{e.Extent.StartLineNumber}: {e.Message}"));
                    LoggingService.Error($"Error parsing script during pre-processing:\n{errorMessages}", component: "MainWindowViewModel");
                    
                    // Also write to console if available for user visibility
                    if (_consoleVm != null)
                    {
                        AppendLine("ERR", $"Script parsing failed:\n{errorMessages}");
                    }
                    
                    // Return original content? Or null? Returning null signals failure.
                    return null; 
                }

                if (scriptBlockAst.ParamBlock == null)
                {
                    LoggingService.Trace("Script has no param block, returning original content.", component: "MainWindowViewModel");
                    return scriptContent; // No param block to modify
                }

                var processedParamBlock = new StringBuilder("param(\n");
                bool firstParam = true;

                // Iterate through the parameters defined in the param block
                foreach (var parameterAst in scriptBlockAst.ParamBlock.Parameters)
                {
                    if (!firstParam) {
                        processedParamBlock.Append(",\n"); // Add comma before subsequent parameters
                    }
                    firstParam = false;

                    // Add standard attributes
                    foreach (var attributeBaseAst in parameterAst.Attributes)
                    {
                        if (attributeBaseAst is AttributeAst attributeAst)
                        {
                            // Check if the attribute is one of the standard ones we want to keep
                            if (standardAttributes.Contains(attributeAst.TypeName.Name))
                            {
                                // Append the original text of the standard attribute
                                processedParamBlock.Append("    "); // Indentation
                                processedParamBlock.Append(attributeAst.Extent.Text); 
                                processedParamBlock.Append("\n");
                                LoggingService.Trace($"  Keeping standard attribute: {attributeAst.Extent.Text}", component: "MainWindowViewModel");
                            }
                            // Else: Skip our custom Wizard* attributes
                            else {
                                LoggingService.Trace($"  Skipping custom attribute: {attributeAst.Extent.Text}", component: "MainWindowViewModel");
                            }
                        }
                        else if (attributeBaseAst is TypeConstraintAst typeConstraintAst) 
                        {
                            // Check if this is actually a Wizard attribute disguised as a type constraint
                            string typeNameText = typeConstraintAst.TypeName.Name;
                            if (typeNameText.StartsWith("Wizard", StringComparison.OrdinalIgnoreCase))
                            {
                                // Skip Wizard* custom attributes
                                LoggingService.Trace($"  Skipping Wizard type constraint: {typeConstraintAst.Extent.Text}", component: "MainWindowViewModel");
                            }
                            else
                            {
                                // Append the original text of the type constraint (e.g., [string], [switch])
                                processedParamBlock.Append("    "); // Indentation
                                processedParamBlock.Append(typeConstraintAst.Extent.Text); 
                                processedParamBlock.Append("\n");
                                LoggingService.Trace($"  Keeping type constraint: {typeConstraintAst.Extent.Text}", component: "MainWindowViewModel");
                            }
                        }
                        // Add other relevant AST node types if necessary (e.g., AliasAttributeAst)
                    }

                    // Add the parameter variable definition (e.g., $ParameterName = DefaultValue)
                    processedParamBlock.Append("    "); // Indentation
                    processedParamBlock.Append(parameterAst.Name.Extent.Text); 
                    if (parameterAst.DefaultValue != null) {
                        processedParamBlock.Append(" = ");
                        processedParamBlock.Append(parameterAst.DefaultValue.Extent.Text);
                    }
                    LoggingService.Trace($"  Adding parameter definition: {parameterAst.Name.Extent.Text}", component: "MainWindowViewModel");
                }

                processedParamBlock.Append("\n)"); // Close the param block

                // Find the end position of the original param block in the script content
                int originalParamBlockEndPos = scriptBlockAst.ParamBlock.Extent.EndOffset;

                // Get the rest of the script body after the param block
                string scriptBody = scriptContent.Substring(originalParamBlockEndPos);

                // Combine the processed param block and the script body
                string finalScript = processedParamBlock.ToString() + scriptBody;

                LoggingService.Info("Script pre-processing complete using AST reconstruction.", component: "MainWindowViewModel");
                // LoggingService.Debug($"Processed Script Content:\n{finalScript}"); // Optional: Log processed script
                return finalScript;
            }
            catch (Exception ex)
            {
                LoggingService.Error($"Error in PreProcessScriptForExecution: {ex.Message}\nStackTrace: {ex.StackTrace}", ex, "MainWindowViewModel");
                
                // Also write to console if available for user visibility
                if (_consoleVm != null)
                {
                    AppendLine("ERR", $"Script preprocessing exception: {ex.Message}");
                    AppendLine("ERR", $"Details: {ex.ToString()}");
                }
                
                return null;
            }
        }

        private void SaveCurrentPageData()
        {
            if (_currentPage is GenericFormViewModel genericFormVm)
            {
                LoggingService.Trace($"Saving data from page '{genericFormVm.Title}' (Index: {_currentPageIndex}) to FormData. Parameter Count: {genericFormVm.Parameters.Count}", component: "MainWindowViewModel");

                foreach (var pvm in genericFormVm.Parameters)
                {
                    object valueToSave = null; 
                    string valueSource = "";
                    
                    if (pvm.IsPassword) // Check if it's a password (SecureString) type
                    {
                        valueToSave = pvm.SecureValue; // Get the SecureString object
                        valueSource = $"SecureValue(Length:{pvm.SecureValue?.Length ?? 0}) -> {valueToSave?.GetType().Name ?? "null"}";
                    }
                    else if (pvm.IsSwitch || pvm.ParameterType == typeof(bool))
                    {
                        // For switches and booleans, save the actual boolean value, not the string representation
                        valueToSave = pvm.BoolValue;
                        valueSource = $"BoolValue({pvm.BoolValue}) -> {valueToSave}";
                        LoggingService.Debug($"SaveCurrentPageData - Switch '{pvm.Name}': BoolValue={pvm.BoolValue}, Type={pvm.BoolValue?.GetType().Name ?? "null"}", component: "MainWindowViewModel");
                    }
                    else if (pvm.IsMultiSelect && pvm.IsListBox)
                    {
                        // For multi-select ListBox (new native ListBox UI), get selections from SelectedItems
                        LoggingService.Debug($"SaveCurrentPageData - Multi-select ListBox '{pvm.Name}', SelectedItems count: {pvm.SelectedItems?.Count ?? 0}", component: "MainWindowViewModel");
                        
                        if (pvm.SelectedItems != null && pvm.SelectedItems.Count > 0)
                        {
                            var selectedItems = pvm.SelectedItems.ToArray();
                            valueToSave = selectedItems;
                            valueSource = $"SelectedItems array: [{string.Join(",", selectedItems)}]";
                            LoggingService.Info($"  - Saving multi-select array for '{pvm.Name}': {selectedItems.Length} items selected", component: "MainWindowViewModel");
                        }
                        else
                        {
                            // Fallback: use empty array
                            valueToSave = new string[0];
                            valueSource = $"Empty array (no SelectedItems)";
                            LoggingService.Warn($"  - Multi-select '{pvm.Name}' has no SelectedItems, using empty array", component: "MainWindowViewModel");
                        }
                    }
                    else if (pvm.IsMultiSelect && pvm.CheckableItems != null)
                    {
                        // For multi-select with checkboxes (legacy UI), get selections from CheckableItems
                        var selectedItems = pvm.CheckableItems
                            .Where(item => item.IsChecked)
                            .Select(item => item.Value)
                            .ToArray();
                        valueToSave = selectedItems;
                        valueSource = $"CheckableItems array: [{string.Join(",", selectedItems)}]";
                        LoggingService.Info($"  - Saving multi-select checkbox array for '{pvm.Name}': {selectedItems.Length} items selected", component: "MainWindowViewModel");
                    }
                    else
                    {
                        valueToSave = pvm.Value; // Get the regular string/object value
                        valueSource = $"Value('{pvm.Value}') -> {valueToSave}";
                    }

                    // --- ADDED Logging before saving ---
                    LoggingService.Trace($"  - Preparing to save FormData['{pvm.Name}']. Source: {valueSource}", component: "MainWindowViewModel");
                    FormData[pvm.Name] = valueToSave; 
                    LoggingService.Debug($"  - Saved FormData['{pvm.Name}'] = '{valueToSave}' (Type: {valueToSave?.GetType().Name ?? "null"})", component: "MainWindowViewModel");
                    // --- END Logging --- 
                }
                LoggingService.Trace($"Finished saving data to FormData for Index {_currentPageIndex}", component: "MainWindowViewModel");
                
                // CRITICAL: Update step validation status after saving
                // This ensures the sidebar checkmark reflects the actual saved data
                UpdateCurrentStepValidation();
                LoggingService.Debug($"Updated step validation after saving data for Index {_currentPageIndex}", component: "MainWindowViewModel");
            }
            else
            {
                LoggingService.Trace($"Current page is not a GenericFormViewModel, skipping data save. Page type: {_currentPage?.GetType().Name}", component: "MainWindowViewModel");
            }
        }

        private void LoadScript(string scriptPath)
        {
            LoggingService.Info($"Attempting to load script: {scriptPath}", component: "MainWindowViewModel");
            
            // Security validation
            if (!SecurityValidator.ValidateScriptPath(scriptPath, out string validationError))
            {
                string errorMsg = $"Script path validation failed: {validationError}";
                LoggingService.Error(errorMsg, component: "MainWindowViewModel");
                CurrentPage = new ErrorViewModel(errorMsg);
                _parsedData = null;
                _wizardSteps.Clear();
                Steps.Clear();
                this._scriptPath = null;
                OnPropertyChanged(nameof(ScriptPath));
                _currentPageIndex = -1;
                UpdateNavigationButtonVisibility();
                return;
            }
            
            // Compute hash for integrity verification
            _scriptHash = SecurityValidator.ComputeFileHash(scriptPath);
            _scriptLoadTime = DateTime.UtcNow;
            
            if (_scriptHash == null)
            {
                string errorMsg = "Failed to compute script hash for security verification";
                LoggingService.Error(errorMsg, component: "MainWindowViewModel");
                AuditLogger.LogSecurityViolation("Hash Computation Failed", scriptPath);
                CurrentPage = new ErrorViewModel(errorMsg);
                return;
            }
            
            // Log script load to audit log
            AuditLogger.LogScriptLoad(scriptPath, _scriptHash);

            // --- ADDED: Set the internal field --- 
            this._scriptPath = scriptPath; // Store the validated script path
            OnPropertyChanged(nameof(ScriptPath)); // Notify UI if bound
            LoggingService.Info($"Internal _scriptPath field set to: {this._scriptPath}", component: "MainWindowViewModel");
            // --- END ADDED --- 

            try
            {
                // Verify hash hasn't changed (TOCTOU protection)
                string currentHash = SecurityValidator.ComputeFileHash(scriptPath);
                if (!string.Equals(_scriptHash, currentHash, StringComparison.OrdinalIgnoreCase))
                {
                    AuditLogger.LogSecurityViolation("Script Modified After Load", 
                        $"File: {scriptPath}\nOriginal Hash: {_scriptHash}\nCurrent Hash: {currentHash}");
                    throw new SecurityException("Script file was modified after initial load. This may indicate tampering.");
                }
                
                // Now use the argument (which is the same as the field we just set)
                LoggingService.Info($"Loading wizard steps from script: {scriptPath}", component: "MainWindowViewModel"); 
                var loadedSteps = _reflectionService.LoadWizardStepsFromScript(scriptPath, out var branding); 
                _parsedData = new ScriptData { WizardSteps = loadedSteps, Branding = branding };
                _wizardSteps = _parsedData?.WizardSteps ?? new List<WizardStep>(); 
                
                LoggingService.Info($"Loaded {_wizardSteps.Count} steps from {scriptPath}.", component: "MainWindowViewModel");
                
                foreach (var step in _wizardSteps) {
                    LoggingService.Trace($"  - Step: {step.Title}, Order: {step.Order}, Params: {step.Parameters.Count}", component: "MainWindowViewModel");
                    foreach (var param in step.Parameters) {
                         LoggingService.Trace($"    - Param: {param.Name}, Type: {param.ParameterType}, Mandatory: {param.IsMandatory}", component: "MainWindowViewModel");
                    }
                }

                // Clear state BEFORE creating new ViewModels
                _pageCache.Clear(); // Clear cached pages when loading new script

                // Pass the argument scriptPath here, as SetStepsFromScript might use it for WindowTitle
                // SetStepsFromScript clears FormData and creates ParameterViewModels
                SetStepsFromScript(_wizardSteps, scriptPath);

                // Initialize dynamic parameters (Phase 2)
                InitializeDynamicParameters();

                // Apply branding after steps are set so it can override defaults
                if (branding != null)
                {
                    LoggingService.Info("Applying WizardBranding from script", component: "MainWindowViewModel");
                    // Apply explicit texts first
                    if (!string.IsNullOrWhiteSpace(branding.WindowTitleText))
                    {
                        WindowTitle = branding.WindowTitleText;
                    }
                    if (!string.IsNullOrWhiteSpace(branding.SidebarHeaderText))
                    {
                        SidebarHeaderText = branding.SidebarHeaderText;
                    }

                    // Apply icons and conditionally suppress default texts when only an icon is specified
                    if (!string.IsNullOrWhiteSpace(branding.WindowTitleIcon))
                    {
                        WindowTitleIconPath = ResolvePathRelativeToScript(branding.WindowTitleIcon);
                        if (string.IsNullOrWhiteSpace(branding.WindowTitleText))
                        {
                            // Icon present but no explicit title text -> clear default title text
                            // Icon present but no explicit title text -> suppress default title text
                            WindowTitle = string.Empty;
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(branding.SidebarHeaderIcon))
                    {
                        // Check if it's a glyph (starts with &#x) - don't resolve as path
                        if (branding.SidebarHeaderIcon.StartsWith("&#x"))
                        {
                            SidebarHeaderIconPath = branding.SidebarHeaderIcon; // Use glyph as-is
                            LoggingService.Info($"Using sidebar icon glyph: {branding.SidebarHeaderIcon}", component: "MainWindowViewModel");
                        }
                        else
                        {
                            SidebarHeaderIconPath = ResolvePathRelativeToScript(branding.SidebarHeaderIcon);
                            LoggingService.Info($"Resolved sidebar icon path: {SidebarHeaderIconPath}", component: "MainWindowViewModel");
                        }
                        if (string.IsNullOrWhiteSpace(branding.SidebarHeaderText))
                        {
                            // Icon present but no explicit sidebar text -> suppress default sidebar header text
                            SidebarHeaderText = string.Empty;
                        }
                    }
                    if (!string.IsNullOrWhiteSpace(branding.SidebarHeaderIconOrientation))
                    {
                        SidebarHeaderIconOrientation = branding.SidebarHeaderIconOrientation;
                        LoggingService.Info($"Applied sidebar icon orientation: {SidebarHeaderIconOrientation}", component: "MainWindowViewModel");
                    }
                    if (!string.IsNullOrWhiteSpace(branding.Theme))
                    {
                        ApplyThemeFromBranding(branding.Theme);
                        LoggingService.Info($"Applied theme from branding: {branding.Theme}", component: "MainWindowViewModel");
                    }
                }

                // --- NEW: Directly initialize CurrentPage for the first step --- 
                if (_wizardSteps != null && _wizardSteps.Count > 0)
                {
                    _currentPageIndex = 0; // Set index before creating page
                    var firstStepInfo = _wizardSteps[0];
                    LoggingService.Trace($"Directly creating initial page (Index 0): Title='{firstStepInfo.Title}', Type='{firstStepInfo.PageType}'", component: "MainWindowViewModel");
                    if (firstStepInfo.PageType == "GenericForm")
                    {
                        // Initial page creation - handle cards properly
                        var formViewModel = new GenericFormViewModel(firstStepInfo.Title ?? "Step 1", firstStepInfo.Description)
                        {
                            Parameters = new ObservableCollection<ParameterViewModel>()
                        };
                        if (firstStepInfo.Parameters != null)
                        { 
                            foreach (var paramInfo in firstStepInfo.Parameters) 
                            { 
                                // Check if this parameter is a card
                                if (!string.IsNullOrEmpty(paramInfo.CardTitle) && !string.IsNullOrEmpty(paramInfo.CardContent))
                                {
                                    LoggingService.Trace($"  - Creating card for initial page: {paramInfo.CardTitle}", component: "MainWindowViewModel");
                                    formViewModel.AdditionalCards.Add(new CardViewModel
                                    {
                                        Title = paramInfo.CardTitle,
                                        Content = paramInfo.CardContent
                                    });
                                    continue; // Skip adding as a parameter control
                                }
                                
                                // Skip placeholder parameters (they don't render as controls)
                                if (paramInfo.IsPlaceholder)
                                {
                                    LoggingService.Trace($"  - Skipping placeholder parameter: {paramInfo.Name}", component: "MainWindowViewModel");
                                    continue;
                                }
                                
                                // Pass null for existingValue as FormData is clear
                                // Pass dialog service to ParameterViewModel constructor
                                var paramVm = new ParameterViewModel(paramInfo, this, null, _dialogService);
                                formViewModel.Parameters.Add(paramVm);
                                
                                // Track for dynamic parameter updates (Phase 2)
                                if (_parameterViewModels != null && !string.IsNullOrEmpty(paramInfo.Name))
                                {
                                    _parameterViewModels[paramInfo.Name] = paramVm;
                                } 
                            } 
                        }
                        CurrentPage = formViewModel;
                    }
                    else if (firstStepInfo.PageType == "Card")
                    {
                        LoggingService.Trace("  - Creating initial Card page", component: "MainWindowViewModel");
                        
                        // Create a form view model to hold parameters and display form controls
                        var formViewModel = new GenericFormViewModel(firstStepInfo.Title ?? "Information", firstStepInfo.Description ?? "")
                        {
                            Parameters = new ObservableCollection<ParameterViewModel>()
                        };
                        
                        // Create and add the main card
                        var mainCard = new CardViewModel
                        {
                            Title = firstStepInfo.Title ?? "Information",
                            Content = firstStepInfo.Description ?? "This is a card for displaying informational text."
                        };
                        
                        // Process parameters for this step
                        if (firstStepInfo.Parameters != null)
                        {
                            LoggingService.Trace($"Processing {firstStepInfo.Parameters.Count} parameters for initial Card page", component: "MainWindowViewModel");
                            
                            foreach (var paramInfo in firstStepInfo.Parameters)
                            {
                                // If this parameter has card properties, create a CardViewModel for it
                                if (!string.IsNullOrEmpty(paramInfo.CardTitle) && !string.IsNullOrEmpty(paramInfo.CardContent))
                                {
                                    LoggingService.Trace($"Creating additional card: {paramInfo.CardTitle}", component: "MainWindowViewModel");
                                    formViewModel.AdditionalCards.Add(new CardViewModel
                                    {
                                        Title = paramInfo.CardTitle,
                                        Content = paramInfo.CardContent
                                    });
                                }
                                // Otherwise, if it's a regular parameter (not a placeholder), add it to the form
                                else if (paramInfo.ParameterType != null && 
                                         !paramInfo.IsPlaceholder && 
                                         !string.IsNullOrEmpty(paramInfo.Label))
                                {
                                    LoggingService.Trace($"Adding parameter control to initial Card page: {paramInfo.Name}", component: "MainWindowViewModel");
                                    var paramVm = new ParameterViewModel(paramInfo, this, null, _dialogService);
                                    formViewModel.Parameters.Add(paramVm);
                                    
                                    // Track for dynamic parameter updates (Phase 2)
                                    if (_parameterViewModels != null && !string.IsNullOrEmpty(paramInfo.Name))
                                    {
                                        _parameterViewModels[paramInfo.Name] = paramVm;
                                    }
                                }
                            }
                        }
                        
                        // Add the main card as the first card
                        formViewModel.AdditionalCards.Insert(0, mainCard);
                        CurrentPage = formViewModel;
                    }
                    else 
                    {
                        LoggingService.Error($"Unsupported first page type: {firstStepInfo.PageType}", component: "MainWindowViewModel");
                        CurrentPage = new ErrorViewModel($"Unsupported first page type: {firstStepInfo.PageType}");
                        return;
                    }
                    LoggingService.Info($"Initial CurrentPage set directly to type {CurrentPage?.GetType().Name}", component: "MainWindowViewModel");

                    // --- Defer ONLY the step indicator update --- 
                    System.Windows.Application.Current.Dispatcher.BeginInvoke(
                        DispatcherPriority.Background, // Keep Background for non-critical UI update
                        new Action(() => {
                            LoggingService.Trace("Dispatcher action (Background): Updating step indicator state for Step 1", component: "MainWindowViewModel");
                            UpdateStepCurrentState(0, 1); // Update IsCurrent visual state for step 1
                            // CurrentStep = 1; // We no longer set CurrentStep here
                            LoggingService.Trace("Dispatcher action (Background): Step indicator state updated", component: "MainWindowViewModel");
                            // Explicitly trigger CanExecuteChanged for buttons after initial page is likely rendered
                            (NextCommand as RelayCommand)?.RaiseCanExecuteChanged();
                            (PreviousCommand as RelayCommand)?.RaiseCanExecuteChanged();
                            (FinishCommand as RelayCommand)?.RaiseCanExecuteChanged();
                        }));
                    // --- END Defer ---
                }
                else
                {
                    CurrentPage = null; // No steps loaded
                    UpdateNavigationButtonVisibility(); // Ensure buttons are updated if no steps
                }
                // --- END NEW --- 
                
                // UpdateNavigationButtonVisibility(); // Now handled by Dispatcher or the else block above
            }
            catch (Exception ex)
            {
                LoggingService.Error("Error in LoadScript", ex, "MainWindowViewModel");
                CurrentPage = new ErrorViewModel("Error loading script: " + ex.Message);
                _parsedData = null;
                _wizardSteps.Clear();
                Steps.Clear();
                this._scriptPath = null; // Clear internal path on error
                OnPropertyChanged(nameof(ScriptPath)); // Notify UI if bound
                _currentPageIndex = -1;
                UpdateNavigationButtonVisibility();
            }
        }

        private void UpdateStepCurrentState(int previousStep, int currentStep)
        {
            if (Steps == null || !Steps.Any()) return;

            int currentZeroBased = currentStep - 1;
            int previousZeroBased = previousStep - 1;

            if (previousZeroBased >= 0 && previousZeroBased < Steps.Count)
            {
                var prevItem = Steps[previousZeroBased];
                if (prevItem != null) prevItem.IsCurrent = false;
            }

            if (currentZeroBased >= 0 && currentZeroBased < Steps.Count)
            {
                var currentItem = Steps[currentZeroBased];
                if (currentItem != null) currentItem.IsCurrent = true;
            }
            else
            {
                LoggingService.Warn($"Warning: CurrentStep index {currentStep} is out of bounds for Steps collection ({Steps.Count} items).", component: "MainWindowViewModel");
            }
        }

        private void Finish(object parameter)
        {
            LoggingService.Info("Finish method called.", component: "MainWindowViewModel");
            // Ensure latest data is saved
            SaveCurrentPageData();

            // Pre-execution validation check
            string summary;
            if (!CollectAllValidationErrors(out summary))
            {
                LoggingService.Warn("Pre-execution validation failed in Finish; blocking execution.", component: "MainWindowViewModel");
                
                // Show detailed validation popup
                System.Windows.MessageBox.Show(
                    $"Please complete the following required fields before continuing:\n\n{summary}",
                    "Required Fields Missing",
                    System.Windows.MessageBoxButton.OK,
                    System.Windows.MessageBoxImage.Warning);
                
                return;
            }
            
            // Pre-execution validation passed, now run the script
            RunScript();
        }

        private bool CanFinish(object parameter)
        {
            bool canFinish = _currentPageIndex >= (_wizardSteps?.Count ?? 0) - 1 && !(_currentPage is ErrorViewModel);
            if (canFinish)
            {
                string msg;
                canFinish = ValidateAllSteps(out msg);
            }
            LoggingService.Trace($"CanFinish check: CurrentPageIndex={_currentPageIndex}, StepCount={_wizardSteps?.Count ?? 0}, IsErrorPage={_currentPage is ErrorViewModel}, Result={canFinish}", component: "MainWindowViewModel");
            return canFinish;
        }

        private void LogViewModelState()
        {
            LoggingService.Trace($"ViewModel State: CurrentStep={CurrentStep}, CurrentPageIndex={_currentPageIndex}, PageType={CurrentPage?.GetType()?.Name}", component: "MainWindowViewModel");
        }

        // Sequential Mode support methods
        public void AddStepDynamic(WizardStep step)
        {
            LoggingService.Info($"AddStepDynamic called for step: {step.Title}", component: "MainWindowViewModel");
            // Sequential mode dynamic step addition - stub for now
        }

        public void OnDynamicStepExecutionFinished(int stepNumber, bool success)
        {
            LoggingService.Info($"OnDynamicStepExecutionFinished called for step {stepNumber}, success: {success}", component: "MainWindowViewModel");
            // Sequential mode step completion callback - stub for now
        }

        private void UpdateNavigationButtonVisibility()
        {
            // Update button text based on current step and page type
            if (CurrentPage is ExecutionConsoleViewModel)
            {
                NextButtonText = "Close";
                CanGoBack = false;
            }
            else if (CurrentStep >= Steps.Count)
            {
                NextButtonText = "Finish";
                CanGoBack = true;
            }
            else if (CurrentStep == Steps.Count)
            {
                NextButtonText = "Finish";
                CanGoBack = true;
            }
            else
            {
                NextButtonText = "Next";
                CanGoBack = CurrentStep > 1;
            }
        }

        // Subscribe to parameter change events to refresh CanExecute state dynamically
        private void SubscribeToFormParameters(GenericFormViewModel form)
        {
            _subscribedForm = form;
            _subscribedParams.Clear();
            if (form.Parameters != null)
            {
                foreach (var p in form.Parameters)
                {
                    if (p != null && !_subscribedParams.Contains(p))
                    {
                        p.PropertyChanged += OnParameterPropertyChanged;
                        _subscribedParams.Add(p);
                    }
                }

                form.Parameters.CollectionChanged += OnParametersCollectionChanged;
            }
        }

        private void UnsubscribeFromFormParameters()
        {
            try
            {
                if (_subscribedForm != null)
                {
                    if (_subscribedForm.Parameters != null)
                    {
                        _subscribedForm.Parameters.CollectionChanged -= OnParametersCollectionChanged;
                        foreach (var p in _subscribedParams)
                        {
                            if (p != null) p.PropertyChanged -= OnParameterPropertyChanged;
                        }
                    }
                }
            }
            finally
            {
                _subscribedParams.Clear();
                _subscribedForm = null;
            }
        }

        private void OnParametersCollectionChanged(object sender, NotifyCollectionChangedEventArgs e)
        {
            if (e.NewItems != null)
            {
                foreach (var obj in e.NewItems)
                {
                    var p = obj as ParameterViewModel;
                    if (p != null && !_subscribedParams.Contains(p))
                    {
                        p.PropertyChanged += OnParameterPropertyChanged;
                        _subscribedParams.Add(p);
                    }
                }
            }
            if (e.OldItems != null)
            {
                foreach (var obj in e.OldItems)
                {
                    var p = obj as ParameterViewModel;
                    if (p != null)
                    {
                        p.PropertyChanged -= OnParameterPropertyChanged;
                        _subscribedParams.Remove(p);
                    }
                }
            }

            (NextCommand as RelayCommand)?.RaiseCanExecuteChanged();
        }

        private void OnParameterPropertyChanged(object sender, PropertyChangedEventArgs e)
        {
            // Any parameter change may affect validation state
            (NextCommand as RelayCommand)?.RaiseCanExecuteChanged();
            (PreviousCommand as RelayCommand)?.RaiseCanExecuteChanged();
            (FinishCommand as RelayCommand)?.RaiseCanExecuteChanged();
            
            // Update current step validation status in real-time
            UpdateCurrentStepValidation();
        }
        
        /// <summary>
        /// Public method to update a parameter value in FormData and refresh validation
        /// Called by ParameterViewModel when values change in real-time
        /// </summary>
        public void UpdateParameterValueAndValidation(string parameterName, object value)
        {
            if (string.IsNullOrEmpty(parameterName)) return;
            
            // Update FormData
            FormData[parameterName] = value;
            
            // Log with type information
            string valueType = value?.GetType().Name ?? "null";
            string valueDisplay = value is Array arr ? $"Array[{arr.Length}]: {string.Join(",", arr.Cast<object>())}" : value?.ToString() ?? "(null)";
            LoggingService.Info($"Real-time update: FormData['{parameterName}'] = {valueDisplay} (Type: {valueType})", component: "MainWindowViewModel");
            
            // Phase 2: Refresh dependent parameters
            RefreshDependentParameters(parameterName);
            
            // Refresh validation status
            UpdateCurrentStepValidation();
        }
        
        private void UpdateCurrentStepValidation()
        {
            if (_currentPageIndex < 0 || _currentPageIndex >= Steps.Count) return;
            
            var currentStepItem = Steps[_currentPageIndex];
            if (currentStepItem == null) return;
            
            // Check if all mandatory fields in this step are filled
            bool wasValid = currentStepItem.IsValid;
            bool isValid = ValidateCurrentStep();
            currentStepItem.IsValid = isValid; // Setter automatically raises PropertyChanged
            
            if (wasValid != isValid)
            {
                LoggingService.Debug($"Step '{currentStepItem.Title}' validation changed: {wasValid} → {isValid}", component: "MainWindowViewModel");
            }
        }
        
        private bool ValidateCurrentStep()
        {
            if (_parsedData?.WizardSteps == null || _currentPageIndex < 0 || _currentPageIndex >= _parsedData.WizardSteps.Count)
                return false;
                
            var currentStep = _parsedData.WizardSteps[_currentPageIndex];
            if (currentStep?.Parameters == null) return true; // No parameters = valid
            
            foreach (var p in currentStep.Parameters)
            {
                if (p == null || !p.IsMandatory) continue;
                
                // Skip placeholder parameters (cards, branding, etc.)
                if (p.IsPlaceholder) continue;
                
                // Get value from FormData
                object valueObj = null;
                FormData?.TryGetValue(p.Name, out valueObj);
                
                bool isBoolType = p.IsSwitch || p.ParameterType == typeof(bool);
                
                bool isEmpty;
                if (isBoolType)
                {
                    isEmpty = false; // switches/bools are never "empty"
                }
                else if (p.ParameterType == typeof(System.Security.SecureString))
                {
                    var ss = valueObj as System.Security.SecureString;
                    isEmpty = ss == null || ss.Length == 0;
                }
                else if (p.ValidateSetChoices != null && p.ValidateSetChoices.Any())
                {
                    var s = valueObj == null ? null : valueObj.ToString();
                    isEmpty = string.IsNullOrEmpty(s);
                }
                else
                {
                    var s = valueObj == null ? null : valueObj.ToString();
                    isEmpty = string.IsNullOrWhiteSpace(s);
                }
                
                if (isEmpty) return false; // At least one mandatory field is empty
            }
            
            return true; // All mandatory fields are filled
        }

        // Centralized validation helpers
        private bool ValidateParameters(IEnumerable<ParameterViewModel> parameters, out string message, bool showMessage = true)
        {
            message = null;
            if (parameters == null) return true;

            var errors = new List<string>();
            
            foreach (var param in parameters)
            {
                LoggingService.LogValidation($"Validating parameter: {param.Name}, Mandatory: {param.IsMandatory}, Value: '{param.Value}'", "MainWindowViewModel");
                
                // Check if parameter is mandatory and empty
                if (param.IsMandatory && string.IsNullOrWhiteSpace(param.Value))
                {
                    var error = $"• {param.Name}: This field is required.";
                    errors.Add(error);
                    LoggingService.LogValidation($"Validation FAILED - {error}", "MainWindowViewModel");
                    continue;
                }

                // Skip further validation if parameter is empty and not mandatory
                if (string.IsNullOrWhiteSpace(param.Value))
                {
                    LoggingService.LogValidation($"Parameter {param.Name} is empty but not mandatory - PASS", "MainWindowViewModel");
                    continue;
                }

                // Validate regex pattern if specified
                if (!string.IsNullOrEmpty(param.ValidationPattern))
                {
                    try
                    {
                        var regex = new Regex(param.ValidationPattern);
                        if (!regex.IsMatch(param.Value))
                        {
                            var error = $"• {param.Name}: Value does not match the required pattern: {param.ValidationPattern}";
                            errors.Add(error);
                            LoggingService.LogValidation($"Regex validation FAILED - {error}", "MainWindowViewModel");
                        }
                        else
                        {
                            LoggingService.LogValidation($"Regex validation PASSED for {param.Name}", "MainWindowViewModel");
                        }
                    }
                    catch (Exception ex)
                    {
                        LoggingService.Error($"Invalid regex pattern for parameter {param.Name}: {param.ValidationPattern}", ex, "MainWindowViewModel");
                        var error = $"• {param.Name}: Invalid validation pattern configured.";
                        errors.Add(error);
                        LoggingService.LogValidation($"Regex validation ERROR - {error}", "MainWindowViewModel");
                    }
                }

                // Validate dropdown membership
                if (param.Choices != null && param.Choices.Any())
                {
                    if (!param.Choices.Contains(param.Value, StringComparer.OrdinalIgnoreCase))
                    {
                        var validOptions = string.Join(", ", param.Choices);
                        var error = $"• {param.Name}: Must be one of: {validOptions}";
                        errors.Add(error);
                        LoggingService.LogValidation($"Dropdown validation FAILED - {error}", "MainWindowViewModel");
                    }
                    else
                    {
                        LoggingService.LogValidation($"Dropdown validation PASSED for {param.Name}", "MainWindowViewModel");
                    }
                }

                // Validate file/folder path existence
                if (param.PathType != Services.PathSelectorType.None && !string.IsNullOrWhiteSpace(param.Value))
                {
                    if (param.PathType == Services.PathSelectorType.Folder)
                    {
                        if (!Directory.Exists(param.Value))
                        {
                            var error = $"• {param.Name}: Folder does not exist: {param.Value}";
                            errors.Add(error);
                            LoggingService.LogValidation($"Path validation FAILED - {error}", "MainWindowViewModel");
                        }
                        else
                        {
                            LoggingService.LogValidation($"Folder path validation PASSED for {param.Name}", "MainWindowViewModel");
                        }
                    }
                    else if (param.PathType == Services.PathSelectorType.File)
                    {
                        if (!File.Exists(param.Value))
                        {
                            var error = $"• {param.Name}: File does not exist: {param.Value}";
                            errors.Add(error);
                            LoggingService.LogValidation($"Path validation FAILED - {error}", "MainWindowViewModel");
                        }
                        else
                        {
                            LoggingService.LogValidation($"File path validation PASSED for {param.Name}", "MainWindowViewModel");
                        }
                    }
                }
            }

            if (errors.Any())
            {
                message = string.Join(Environment.NewLine, errors);
                LoggingService.LogValidation($"Overall validation FAILED with {errors.Count} errors", "MainWindowViewModel");
                if (showMessage)
                {
                    MessageBox.Show(message, "Validation Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                }
                return false;
            }

            LoggingService.LogValidation("Overall validation PASSED", "MainWindowViewModel");
            return true;
        }

        private bool ValidateAllSteps(out string message)
        {
            // This method is replaced by the more comprehensive CollectAllValidationErrors
            // Just delegate to that method for consistency
            return CollectAllValidationErrors(out message);
        }

        // Build an aggregated validation summary across all steps. Returns true if no errors.
        private bool CollectAllValidationErrors(out string summary)
        {
            LoggingService.Debug("!!! CollectAllValidationErrors method entered !!!", component: "MainWindowViewModel");
            var steps = _parsedData?.WizardSteps;
            var errors = new List<string>();
            summary = null;
            
            LoggingService.Debug($"!!! Steps count: {steps?.Count ?? 0} !!!", component: "MainWindowViewModel");
            if (steps == null || steps.Count == 0) 
            {
                LoggingService.Debug("!!! No steps found, returning true !!!", component: "MainWindowViewModel");
                return true;
            }

            // Ensure current page data is captured
            try { SaveCurrentPageData(); } catch { }

            for (int i = 0; i < steps.Count; i++)
            {
                var step = steps[i];
                if (step?.Parameters == null) continue;
                var stepNum = i + 1;
                LoggingService.Debug($"!!! Processing step {stepNum}: '{step.Title}' with {step.Parameters?.Count ?? 0} parameters !!!", component: "MainWindowViewModel");
                foreach (var p in step.Parameters)
                {
                    if (p == null) continue;
                    
                    // Skip placeholder parameters (cards, branding, etc.) - they don't need validation
                    if (p.IsPlaceholder)
                    {
                        LoggingService.Debug($"!!! Skipping placeholder parameter '{p.Name}' !!!", component: "MainWindowViewModel");
                        continue;
                    }

                    var isBoolType = p.IsSwitch || p.ParameterType == typeof(bool);
                    object valueObj = null;
                    bool hasValue = FormData.TryGetValue(p.Name, out valueObj);
                    string valueTypeInfo = valueObj != null ? $"Type={valueObj.GetType().Name}" : "null";
                    LoggingService.Debug($"!!! Parameter '{p.Name}': IsMandatory={p.IsMandatory}, HasValue={hasValue}, Value='{valueObj}', {valueTypeInfo} !!!", component: "MainWindowViewModel");
                    
                    bool isSecure = (valueObj is SecureString) || p.ParameterType == typeof(SecureString);
                    if (isSecure && p.ParameterType != typeof(SecureString))
                    {
                        LoggingService.Trace($"Validation: Parameter '{p.Name}' has SecureString value but ParameterType={p.ParameterType}. Treating as password.", component: "MainWindowViewModel");
                    }

                    // Mandatory check
                    if (p.IsMandatory)
                    {
                        LoggingService.Debug($"!!! Checking mandatory parameter '{p.Name}' !!!", component: "MainWindowViewModel");
                        bool isEmpty;
                        if (isBoolType)
                        {
                            isEmpty = false;
                        }
                        else if (isSecure)
                        {
                            var ss = valueObj as SecureString;
                            isEmpty = ss == null || ss.Length == 0;
                        }
                        else
                        {
                            var s = valueObj == null ? null : valueObj.ToString();
                            isEmpty = string.IsNullOrWhiteSpace(s);
                        }

                        if (isEmpty)
                        {
                            errors.Add($"Step {stepNum} '{step.Title}': '{p.Label ?? p.Name}' is required.");
                            continue; // No need to run other validations on empty
                        }
                    }

                    // Dropdown membership validation
                    if (!isBoolType && p.ValidateSetChoices != null && p.ValidateSetChoices.Any())
                    {
                        LoggingService.Debug($"!!! ValidateSet check for '{p.Name}': valueObj is Array? {valueObj is Array}, Type={valueObj?.GetType().Name} !!!", component: "MainWindowViewModel");
                        
                        // Handle array values (from multi-select ListBox)
                        if (valueObj is Array arrayValue)
                        {
                            LoggingService.Debug($"!!! Validating array for '{p.Name}': {arrayValue.Length} items !!!", component: "MainWindowViewModel");
                            foreach (var item in arrayValue)
                            {
                                var itemStr = item?.ToString();
                                if (!string.IsNullOrEmpty(itemStr) && !p.ValidateSetChoices.Contains(itemStr))
                                {
                                    errors.Add($"Step {stepNum} '{step.Title}': '{p.Label ?? p.Name}' has invalid value '{itemStr}'. Valid options: {string.Join(", ", p.ValidateSetChoices)}.");
                                }
                            }
                        }
                        else
                        {
                            LoggingService.Debug($"!!! Validating string for '{p.Name}': '{valueObj}' !!!", component: "MainWindowViewModel");
                            var s = valueObj == null ? null : valueObj.ToString();
                            if (!string.IsNullOrEmpty(s) && !p.ValidateSetChoices.Contains(s))
                            {
                                errors.Add($"Step {stepNum} '{step.Title}': '{p.Label ?? p.Name}' has invalid value '{s}'. Valid options: {string.Join(", ", p.ValidateSetChoices)}.");
                            }
                        }
                    }

                    // Path existence validation
                    if (!isBoolType && p.PathType != Services.PathSelectorType.None)
                    {
                        var s = valueObj == null ? null : valueObj.ToString();
                        if (!string.IsNullOrWhiteSpace(s))
                        {
                            if (p.PathType == Services.PathSelectorType.File && !File.Exists(s))
                            {
                                errors.Add($"Step {stepNum} '{step.Title}': File '{s}' for '{p.Label ?? p.Name}' does not exist.");
                            }
                            else if (p.PathType == Services.PathSelectorType.Folder && !Directory.Exists(s))
                            {
                                errors.Add($"Step {stepNum} '{step.Title}': Folder '{s}' for '{p.Label ?? p.Name}' does not exist.");
                            }
                        }
                    }

                    // Regex check
                    if (!isBoolType && !string.IsNullOrEmpty(p.ValidationPattern))
                    {
                        try
                        {
                            if (isSecure)
                            {
                                var ss = valueObj as SecureString;
                                if (ss != null && ss.Length > 0 && !SecureStringMatchesPattern(ss, p.ValidationPattern))
                                {
                                    errors.Add($"Step {stepNum} '{step.Title}': '{p.Label ?? p.Name}' does not match the required format.");
                                }
                            }
                            else
                            {
                                var s = valueObj == null ? null : valueObj.ToString();
                                if (!string.IsNullOrEmpty(s) && !Regex.IsMatch(s, p.ValidationPattern))
                                {
                                    errors.Add($"Step {stepNum} '{step.Title}': '{p.Label ?? p.Name}' does not match the required format.");
                                }
                            }
                        }
                        catch (ArgumentException)
                        {
                            // Invalid pattern configured; treat as error entry for visibility
                            errors.Add($"Step {stepNum} '{step.Title}': Invalid validation pattern for '{p.Label ?? p.Name}'.");
                        }
                    }
                }
            }

            if (errors.Count > 0)
            {
                var sb = new StringBuilder();
                sb.AppendLine("Please resolve the following before execution:");
                foreach (var e in errors)
                {
                    sb.AppendLine(" • " + e);
                }
                summary = sb.ToString();
                return false;
            }

            return true;
        }

        // Helper to validate SecureString content against a regex pattern safely
        private bool SecureStringMatchesPattern(SecureString secureString, string pattern)
        {
            if (secureString == null || secureString.Length == 0) return true; // nothing to validate

            IntPtr bstr = IntPtr.Zero;
            string plaintext = null;
            try
            {
                bstr = Marshal.SecureStringToBSTR(secureString);
                plaintext = Marshal.PtrToStringBSTR(bstr);
                if (string.IsNullOrEmpty(plaintext)) return true; // treat empty as no value to check
                return Regex.IsMatch(plaintext, pattern);
            }
            finally
            {
                if (bstr != IntPtr.Zero) Marshal.ZeroFreeBSTR(bstr);
                // Best-effort clear managed string reference
                plaintext = null;
            }
        }

        private bool IsSystemDarkTheme()
        {
            try
            {
                const string personalizeKey = @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize";
                using (var key = Registry.CurrentUser.OpenSubKey(personalizeKey))
                {
                    if (key != null)
                    {
                        var value = key.GetValue("AppsUseLightTheme");
                        if (value is int intValue)
                        {
                            return intValue == 0;
                        }

                        if (value != null && int.TryParse(value.ToString(), out int parsedValue))
                        {
                            return parsedValue == 0;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LoggingService.Warn($"Failed to read system theme preference: {ex.Message}", component: "MainWindowViewModel");
            }

            // Default to light theme if detection fails
            return false;
        }

        // Apply theme from wizard branding
        private void ApplyThemeFromBranding(string theme)
        {
            if (string.IsNullOrWhiteSpace(theme))
                return;

            // Normalize theme value
            theme = theme.Trim();
            
            Application.Current.Dispatcher.Invoke(() =>
            {
                try
                {
                    var merged = Application.Current.Resources.MergedDictionaries;
                    
                    // Remove existing theme dictionaries
                    for (int i = merged.Count - 1; i >= 0; i--)
                    {
                        var src = merged[i].Source;
                        if (src != null)
                        {
                            var s = src.OriginalString ?? string.Empty;
                            if (s.EndsWith("/Assets/Fluent.xaml", StringComparison.OrdinalIgnoreCase) ||
                                s.EndsWith("/Assets/DarkTheme.xaml", StringComparison.OrdinalIgnoreCase))
                            {
                                merged.RemoveAt(i);
                            }
                        }
                    }
                    
                    // Apply requested theme
                    string themePath = null;
                    if (theme.Equals("Dark", StringComparison.OrdinalIgnoreCase))
                    {
                        themePath = "/Assets/DarkTheme.xaml";
                    }
                    else if (theme.Equals("Light", StringComparison.OrdinalIgnoreCase))
                    {
                        themePath = "/Assets/Fluent.xaml";
                    }
                    else if (theme.Equals("Auto", StringComparison.OrdinalIgnoreCase))
                    {
                        bool isDarkTheme = IsSystemDarkTheme();
                        themePath = isDarkTheme ? "/Assets/DarkTheme.xaml" : "/Assets/Fluent.xaml";
                        LoggingService.Info($"Auto theme selected. System theme detected as {(isDarkTheme ? "Dark" : "Light")}", component: "MainWindowViewModel");
                    }
                    
                    if (!string.IsNullOrEmpty(themePath))
                    {
                        var newDict = new ResourceDictionary { Source = new Uri(themePath, UriKind.Relative) };
                        merged.Insert(0, newDict);
                        
                        // Notify custom controls to refresh
                        ThemeManager.NotifyThemeChanged();
                        
                        // Notify UI to sync theme toggle button
                        ThemeChanged?.Invoke(this, EventArgs.Empty);
                        
                        LoggingService.Info($"Theme applied successfully: {theme} -> {themePath}", component: "MainWindowViewModel");
                    }
                }
                catch (Exception ex)
                {
                    LoggingService.Error($"Failed to apply theme: {theme}", ex, component: "MainWindowViewModel");
                }
            });
        }

        // Exposed for window closing validation
        public bool CanClose(out string message)
        {
            message = null;
            
            // Show confirmation dialog when user tries to close
            var result = System.Windows.MessageBox.Show(
                "Are you sure you want to close the application?",
                "Confirm Close",
                System.Windows.MessageBoxButton.YesNo,
                System.Windows.MessageBoxImage.Question);
            
            return result == System.Windows.MessageBoxResult.Yes;
        }

        /// <summary>
        /// Serializes FormData to JSON format for Module API return values.
        /// Handles SecureString conversion and ensures all data types are JSON-serializable.
        /// </summary>
        private void SerializeFormDataToJson()
        {
            try
            {
                LoggingService.Info($"SerializeFormDataToJson called. FormData count: {FormData?.Count ?? 0}", component: "MainWindowViewModel");
                
                if (FormData == null || !FormData.Any())
                {
                    LoggingService.Warn("No FormData to serialize", component: "MainWindowViewModel");
                    LastExecutionResult = "{}";
                    return;
                }

                // Create a serializable version of FormData
                var serializableData = new Dictionary<string, object>();

                foreach (var kvp in FormData)
                {
                    LoggingService.Info($"Processing FormData parameter: {kvp.Key} = '{kvp.Value}' (Type: {kvp.Value?.GetType().Name ?? "null"})", component: "MainWindowViewModel");
                    
                    object value = kvp.Value;

                    // Exclude SecureString parameters for security (no plaintext exposure)
                    if (value is System.Security.SecureString)
                    {
                        LoggingService.Info($"Excluding SecureString parameter '{kvp.Key}' from JSON output for security", component: "MainWindowViewModel");
                        continue; // Skip this parameter entirely
                    }

                    // Workaround: If a parameter that should be a single value is stored as a single-element array,
                    // flatten it back to the single value. This fixes issues where single text box parameters
                    // are incorrectly stored as arrays.
                    if (value is Array array && array.Length == 1)
                    {
                        value = array.GetValue(0);
                        LoggingService.Debug($"Flattened single-element array for parameter '{kvp.Key}' to: {value}", component: "MainWindowViewModel");
                    }

                    // Arrays and other complex types should already be JSON-serializable
                    // bool, string, int, etc. are already serializable

                    serializableData[kvp.Key] = value;
                }

                LoggingService.Info($"Serializing {serializableData.Count} parameters to JSON", component: "MainWindowViewModel");
                
                // Serialize to JSON
                using (var ms = new System.IO.MemoryStream())
                {
                    var serializer = new System.Runtime.Serialization.Json.DataContractJsonSerializer(
                        typeof(Dictionary<string, object>),
                        new System.Runtime.Serialization.Json.DataContractJsonSerializerSettings
                        {
                            UseSimpleDictionaryFormat = true
                        });
                    serializer.WriteObject(ms, serializableData);
                    ms.Position = 0;
                    using (var reader = new System.IO.StreamReader(ms))
                    {
                        LastExecutionResult = reader.ReadToEnd();
                    }
                }

                LoggingService.Info($"FormData serialized to JSON: {LastExecutionResult}", component: "MainWindowViewModel");
            }
            catch (Exception ex)
            {
                LoggingService.Error($"Failed to serialize FormData to JSON: {ex.Message}", ex, component: "MainWindowViewModel");
                // Fallback to empty JSON object
                LastExecutionResult = "{}";
            }
        }

        /// <summary>
        /// Safely converts a SecureString to plaintext.
        /// </summary>
        private string SecureStringToPlainText(System.Security.SecureString secureString)
        {
            if (secureString == null)
                return null;

            IntPtr bstr = IntPtr.Zero;
            try
            {
                bstr = Marshal.SecureStringToBSTR(secureString);
                return Marshal.PtrToStringBSTR(bstr);
            }
            finally
            {
                if (bstr != IntPtr.Zero)
                    Marshal.ZeroFreeBSTR(bstr);
            }
        }
    }
} 