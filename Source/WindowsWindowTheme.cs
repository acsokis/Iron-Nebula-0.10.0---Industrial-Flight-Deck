using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace IronNebula;

internal static class WindowsWindowTheme
{
    private const int DarkModeAttribute = 20;
    private const int LegacyDarkModeAttribute = 19;

    [DllImport("dwmapi.dll", PreserveSig = true)]
    private static extern int DwmSetWindowAttribute(
        IntPtr window,
        int attribute,
        ref int value,
        int valueSize);

    internal static void ApplyDarkTitleBar(IntPtr window)
    {
        if (!OperatingSystem.IsWindows() || window == IntPtr.Zero)
            return;

        int enabled = 1;
        int result = DwmSetWindowAttribute(window, DarkModeAttribute, ref enabled, sizeof(int));
        if (result != 0)
            result = DwmSetWindowAttribute(window, LegacyDarkModeAttribute, ref enabled, sizeof(int));

        if (result != 0)
            Trace.WriteLine($"Could not apply the dark Windows title bar (HRESULT 0x{result:X8}).");
    }
}
