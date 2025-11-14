// Copyright (c) 2025 A Solution IT LLC. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for full license information.
using System;
using System.Windows.Input;
using System.IO;

namespace Launcher.ViewModels
{
    public class RelayCommand : ICommand
    {
        private readonly Action<object> _execute;
        private readonly Func<object, bool> _canExecute;
        private static int commandCounter = 0;
        private int commandId;

        public event EventHandler CanExecuteChanged;

        public RelayCommand(Action<object> execute, Func<object, bool> canExecute = null)
        {
            if (execute == null)
            {
                throw new ArgumentNullException("execute");
            }
            _execute = execute;
            _canExecute = canExecute;
            commandId = ++commandCounter;
            LogCommandAction("RelayCommand created");
        }

        public bool CanExecute(object parameter)
        {
            bool result = _canExecute == null || _canExecute(parameter);
            LogCommandAction(string.Format("CanExecute called, result: {0}", result));
            return result;
        }

        public void Execute(object parameter)
        {
            LogCommandAction("Execute called");
            try
            {
                _execute(parameter);
                LogCommandAction("Execute completed");
            }
            catch (Exception ex)
            {
                LogCommandAction(string.Format("Execute error: {0}", ex.Message));
                throw;
            }
        }
        
        public void RaiseCanExecuteChanged()
        {
            LogCommandAction("RaiseCanExecuteChanged called");
            // Safely raise the event on the UI thread if necessary
            // For simplicity here, directly invoking. Consider Dispatcher for complex scenarios.
            CanExecuteChanged?.Invoke(this, EventArgs.Empty);
        }

        private void LogCommandAction(string action)
        {
            try
            {
                string message = string.Format("[{0}] Command #{1}: {2}", 
                    DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff"), 
                    commandId, 
                    action);
                    
                string logDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                Directory.CreateDirectory(logDirectory);
                string logPath = Path.Combine(logDirectory, "CommandLog.txt");
                File.AppendAllText(logPath, message + Environment.NewLine);
            }
            catch
            {
                // Ignore logging failures
            }
        }
    }
} 