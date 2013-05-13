#include <QtGui/QApplication>
#include "mainwindow.h"
#include <Qt>
#include <QtGui>
#include <QSystemTrayIcon>

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);
    MainWindow w;
    return a.exec();
}