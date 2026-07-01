QT += core quick network quickcontrols2 svg dbus
CONFIG += c++17 link_pkgconfig
TEMPLATE = app
TARGET = moonlight-kiosk

PKGCONFIG += sdl2

packagesExist(libcec) {
    PKGCONFIG += libcec
    DEFINES += HAS_CEC
}

SOURCES += \
    main.cpp \
    bluetoothmanager.cpp \
    wifimanager.cpp \
    cecmanager.cpp

HEADERS += \
    bluetoothmanager.h \
    wifimanager.h \
    cecmanager.h

RESOURCES += qml.qrc

target.path = /usr/local/bin/
INSTALLS += target
