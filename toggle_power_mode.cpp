#include <iostream>
#include <fstream>
#include <cstdlib>
#include <sstream>
#include <algorithm>

void sendHyprlandNotification(const std::string& info, const std::string& message) {
    std::string command = "hyprctl notify " + info + " 3000 \"0\" \"fontsize:24   " + message + "\"";
    system(command.c_str());
}

bool isPluggedIn() {
    std::ifstream powerStatus("/sys/class/power_supply/ADP0/online");
    if (!powerStatus) {
        sendHyprlandNotification("0", "Ошибка: не удалось определить статус питания");
        return false;
    }

    int status;
    powerStatus >> status;
    powerStatus.close();

    return status == 1;
}

std::string trimNullBytes(const std::string& input) {
    std::string result = input;
    result.erase(std::remove(result.begin(), result.end(), '\0'), result.end());
    return result;
}

int getCurrentPerformanceMode() {
    std::ofstream acpiCall("/proc/acpi/call");
    if (!acpiCall) {
        sendHyprlandNotification("0", "Ошибка: не удалось проверить режим производительности");
        return -1;
    }

    acpiCall << "\\_SB.PCI0.LPC0.EC0.SPMO";
    acpiCall.close();

    std::ifstream acpiResult("/proc/acpi/call");
    if (!acpiResult) {
        sendHyprlandNotification("0", "Ошибка: не удалось получить режим производительности");
        return -1;
    }

    std::stringstream buffer;
    buffer << acpiResult.rdbuf();
    std::string result = buffer.str();
    result = trimNullBytes(result);
    acpiResult.close();

    if (result == "0x0") return 0;  // Intelligent Cooling
    if (result == "0x1") return 1;  // Extreme Performance
    if (result == "0x2") return 2;  // Battery Saving

    sendHyprlandNotification("0", "Ошибка: неизвестный режим производительности");

    return -1;
}

void setPerformanceMode(int mode) {
    std::ofstream acpiCall("/proc/acpi/call");
    if (!acpiCall) {
        sendHyprlandNotification("0", "Ошибка: не удалось изменить режим производительности");
        return;
    }

    if (mode == 0) {
        acpiCall << "\\_SB_.GZFD.WMAA 0 0x2C 2";  // Intelligent Cooling
        sendHyprlandNotification("2", "Режим: Intelligent Cooling");
    } else if (mode == 1) {
        acpiCall << "\\_SB_.GZFD.WMAA 0 0x2C 3";  // Extreme Performance
        sendHyprlandNotification("2", "Режим: Extreme Performance");
    } else if (mode == 2) {
        acpiCall << "\\_SB_.GZFD.WMAA 0 0x2C 1";  // Battery Saving
        sendHyprlandNotification("2", "Режим: Battery Saving");
    }

    acpiCall.close();
}

void togglePerformanceMode() {
    bool pluggedIn = isPluggedIn();
    int currentMode = getCurrentPerformanceMode();
    if (currentMode == -1) {
        std::cerr << "Не удалось определить текущий режим.\n";
        return;
    }

    int nextMode;

    if (pluggedIn) {
        nextMode = (currentMode + 1) % 3;
    } else {
        if (currentMode == 0) {
            nextMode = 2;
        } else if (currentMode == 2) {
            nextMode = 0;
        }
    }

    setPerformanceMode(nextMode);
}

int main() {
    togglePerformanceMode();
    return 0;
}
