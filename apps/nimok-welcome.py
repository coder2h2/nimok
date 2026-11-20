#!/usr/bin/env python3
# Nimok Linux is a Linux Distro for coding and gaming
# Copyright (C) 2026  Gideon Laurie
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

import sys
import subprocess
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QCheckBox
)
from PyQt6.QtGui import QPixmap, QIcon
from PyQt6.QtCore import Qt
import os

AUTOSTART_FILE = os.path.expanduser("~/.config/autostart/nimok-welcome.desktop")

class NimokWelcome(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Welcome to Nimok Linux 0.1 (Nifoun)")
        self.setFixedSize(560, 420)
        if os.path.exists("/usr/share/pixmaps/nimok-logo.png"):
            self.setWindowIcon(QIcon("/usr/share/pixmaps/nimok-logo.png"))

        self.setStyleSheet("""
            QWidget { background-color: #1e1e2e; color: #cdd6f4; font-family: sans-serif; }
            QPushButton {
                background-color: #313244; border: 1px solid #45475a;
                border-radius: 6px; padding: 10px 16px; font-size: 14px; font-weight: bold;
            }
            QPushButton:hover { background-color: #45475a; border-color: #89b4fa; }
            QPushButton#installBtn { background-color: #89b4fa; color: #11111b; }
            QPushButton#installBtn:hover { background-color: #b4befe; }
        """)

        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.setSpacing(14)

        logo = QLabel()
        if os.path.exists("/usr/share/pixmaps/nimok-logo.png"):
            pix = QPixmap("/usr/share/pixmaps/nimok-logo.png").scaled(
                110, 110, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation
            )
            logo.setPixmap(pix)
        logo.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(logo)

        title = QLabel("Welcome to Nimok Linux 0.1 (Nifoun)")
        title.setStyleSheet("font-size: 22px; font-weight: bold; color: #89b4fa;")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title)

        subtitle = QLabel("A modular Coding and Gaming Distro powered by Linux 7.3.5-nimok.")
        subtitle.setStyleSheet("font-size: 13px; color: #a6adc8;")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(subtitle)

        btn_row1 = QHBoxLayout()
        install_btn = QPushButton("Install Nimok Linux")
        install_btn.setObjectName("installBtn")
        install_btn.clicked.connect(lambda: subprocess.Popen(["sudo", "calamares"]))
        btn_row1.addWidget(install_btn)

        web_btn = QPushButton("GitHub & Docs")
        web_btn.clicked.connect(lambda: subprocess.Popen(["xdg-open", "https://github.com"]))
        btn_row1.addWidget(web_btn)
        layout.addLayout(btn_row1)

        btn_row2 = QHBoxLayout()
        term_btn = QPushButton("Open Konsole Terminal")
        term_btn.clicked.connect(lambda: subprocess.Popen(["konsole"]))
        btn_row2.addWidget(term_btn)

        settings_btn = QPushButton("System Settings")
        settings_btn.clicked.connect(lambda: subprocess.Popen(["systemsettings"]))
        btn_row2.addWidget(settings_btn)
        layout.addLayout(btn_row2)

        self.autostart_cb = QCheckBox("Show this welcome screen on startup")
        self.autostart_cb.setChecked(os.path.exists(AUTOSTART_FILE))
        self.autostart_cb.stateChanged.connect(self.toggle_autostart)
        layout.addWidget(self.autostart_cb, alignment=Qt.AlignmentFlag.AlignCenter)

    def toggle_autostart(self, state):
        if state == Qt.CheckState.Checked.value:
            os.makedirs(os.path.dirname(AUTOSTART_FILE), exist_ok=True)
            with open(AUTOSTART_FILE, "w") as f:
                f.write("[Desktop Entry]\nType=Application\nName=Nimok Welcome\nExec=/usr/bin/nimok-welcome\nIcon=/usr/share/pixmaps/nimok-logo.png\n")
        elif os.path.exists(AUTOSTART_FILE):
            os.remove(AUTOSTART_FILE)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = NimokWelcome()
    win.show()
    sys.exit(app.exec())
