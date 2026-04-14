#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

bool GetRealWindowsVersion(DWORD& major, DWORD& minor, DWORD& build) {
  HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  if (!ntdll) {
    return false;
  }

  using RtlGetVersionPtr = LONG(WINAPI*)(PRTL_OSVERSIONINFOW);
  auto rtl_get_version =
      reinterpret_cast<RtlGetVersionPtr>(::GetProcAddress(ntdll, "RtlGetVersion"));
  if (!rtl_get_version) {
    return false;
  }

  RTL_OSVERSIONINFOW info = {};
  info.dwOSVersionInfoSize = sizeof(info);
  if (rtl_get_version(&info) != 0) {
    return false;
  }

  major = info.dwMajorVersion;
  minor = info.dwMinorVersion;
  build = info.dwBuildNumber;
  return true;
}

bool IsAtLeastWindows10Build14393() {
  DWORD major = 0;
  DWORD minor = 0;
  DWORD build = 0;
  if (!GetRealWindowsVersion(major, minor, build)) {
    return true;
  }
  if (major > 10) {
    return true;
  }
  if (major < 10) {
    return false;
  }
  return build >= 14393;
}

void ShowUnsupportedWindowsMessage() {
  DWORD major = 0;
  DWORD minor = 0;
  DWORD build = 0;
  std::wstring current = L"未知";
  if (GetRealWindowsVersion(major, minor, build)) {
    current = std::to_wstring(major) + L"." + std::to_wstring(minor) + L"." +
              std::to_wstring(build);
  }

  std::wstring message =
      L"该程序需要 Windows 10 1607 (Build 14393) 或更高版本。\n"
      L"当前系统版本: " +
      current +
      L"\n\n"
      L"This app requires Windows 10 1607 (Build 14393) or later.\n"
      L"Current: " +
      current;

  ::MessageBoxW(nullptr, message.c_str(), L"Life's Been Good System",
                MB_OK | MB_ICONERROR | MB_TOPMOST);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  if (!IsAtLeastWindows10Build14393()) {
    ShowUnsupportedWindowsMessage();
    return EXIT_FAILURE;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Life's Been Good System", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
