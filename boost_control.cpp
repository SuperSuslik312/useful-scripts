#include <iostream>
#include <fstream>
#include <cstdlib>

void sendHyprlandNotification(const std::string& info, const std::string& message) {
    std::string command = "hyprctl notify " + info + " 3000 \"0\" \"fontsize:24   " + message + "\"";
    system(command.c_str());
}

bool isTurboBoostEnabled() {
    std::ifstream boostFile("/sys/devices/system/cpu/cpufreq/boost");
    if (!boostFile) {
        sendHyprlandNotification("0", "Ошибка: нет доступа к состоянию Turbo Boost");
        return false;
    }

    int state;
    boostFile >> state;
    boostFile.close();

    return state == 1;
}

void toggleTurboBoost() {
    bool currentState = isTurboBoostEnabled();
    std::ofstream boostFile("/sys/devices/system/cpu/cpufreq/boost");
    if (!boostFile) {
        sendHyprlandNotification("0", "Ошибка: нет доступа к управлению Turbo Boost");
        return;
    }

    boostFile << (currentState ? "0" : "1");
    boostFile.close();

    if (currentState) {
        sendHyprlandNotification("3", "Turbo Boost отключён");
    } else {
        sendHyprlandNotification("5", "Turbo Boost включён");
    }
}

int main() {
    toggleTurboBoost();
    return 0;
}
