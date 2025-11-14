// Copyright (c) 2025 A Solution IT LLC. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for full license information.
using System.ComponentModel;

namespace Launcher.ViewModels
{
    /// <summary>
    /// Represents a single step item in the wizard navigation
    /// </summary>
    public class StepItem : INotifyPropertyChanged
    {
        public int StepNumber { get; set; }
        public string Title { get; set; }
        
        private bool _isCompleted;
        public bool IsCompleted
        {
            get => _isCompleted;
            set
            {
                if (_isCompleted == value) return;
                _isCompleted = value;
                OnPropertyChanged(nameof(IsCompleted));
            }
        }
        
        private bool _isCurrent;
        public bool IsCurrent
        {
            get => _isCurrent;
            set
            {
                if (_isCurrent == value) return;
                _isCurrent = value;
                OnPropertyChanged(nameof(IsCurrent));
            }
        }
        
        private bool _isValid;
        public bool IsValid
        {
            get => _isValid;
            set
            {
                if (_isValid == value) return;
                _isValid = value;
                OnPropertyChanged(nameof(IsValid));
            }
        }
        
        public string IconGlyph { get; set; }  // Fluent icon glyph for this step
        
        public bool ShowConnector { get; set; }
        public string Tag { get; set; }

        public event PropertyChangedEventHandler PropertyChanged;
        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }
    }
}
