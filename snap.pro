QT += core gui network
TARGET = snap
TEMPLATE = app
CONFIG += app_bundle

SOURCES +=  main.mm \
            mainwindow.mm

HEADERS  += mainwindow.h

FORMS    += mainwindow.ui

LIBS =  /usr/local/Trolltech/Qt-4.7.2/lib/libQtCore.a \
        /usr/local/Trolltech/Qt-4.7.2/lib/libQtGui.a \
        /usr/local/Trolltech/Qt-4.7.2/lib/libQtNetwork.a

OBJECTIVE_SOURCES += ns.mm

LIBS += -framework Cocoa

LIBS += -framework Carbon
LIBS += -framework AppKit

QMAKE_CFLAGS_RELEASE += -fvisibility=hidden
QMAKE_CXXFLAGS_RELEASE += -fvisibility=hidden -fvisibility-inlines-hidden

RESOURCES += rc.qrc