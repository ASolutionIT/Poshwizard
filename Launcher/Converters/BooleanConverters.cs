// Copyright (c) 2025 A Solution IT LLC. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root for full license information.
using System;
using System.Collections;
using System.Globalization;
using System.Windows.Data;

namespace Launcher.Converters
{
    /// <summary>
    /// Converts null to false, everything else to true.
    /// Used to check if a binding (like Choices) is not null.
    /// </summary>
    public class NullToFalseConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return value != null;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class CountToTrueConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null)
            {
                return false;
            }

            if (value is int intValue)
            {
                return intValue > 0;
            }

            if (value is IEnumerable enumerable)
            {
                foreach (var _ in enumerable)
                {
                    return true;
                }
                return false;
            }

            if (int.TryParse(value.ToString(), out int parsed))
            {
                return parsed > 0;
            }

            return false;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    public class EqualityToBooleanConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (parameter == null)
            {
                return value == null;
            }

            return Equals(value?.ToString(), parameter.ToString());
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is bool boolValue && boolValue)
            {
                return parameter;
            }

            return Binding.DoNothing;
        }
    }

    public class RowCountToHeightConverter : IValueConverter
    {
        private const double DefaultRowHeight = 26.0;
        private const double MinimumHeight = 60.0;

        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value == null)
            {
                return MinimumHeight;
            }

            if (!int.TryParse(value.ToString(), out int rows) || rows <= 0)
            {
                rows = 4; // sensible default
            }

            double calculated = rows * DefaultRowHeight;
            return Math.Max(calculated, MinimumHeight);
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}