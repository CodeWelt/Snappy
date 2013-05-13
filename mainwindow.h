#ifndef MAINWINDOW_H
#define MAINWINDOW_H
#include </System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Headers/CGWindow.h>
#include </System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Headers/CGWindowLevel.h>
#include </System/Library/Frameworks/ApplicationServices.framework/Frameworks/CoreGraphics.framework/Headers/CoreGraphics.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFarray.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFNumber.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CoreFoundation.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFBase.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFArray.h>
#include </System/Library/Frameworks/CoreFoundation.framework/Versions/A/Headers/CFString.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>

#include <Qt>
#include <QtGui>
#include <QSystemTrayIcon>
#include <QFtp>
#include <QMainWindow>

#include <iostream>

namespace Ui {
    class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:
    Ui::MainWindow *ui;
    int showMessage(QString, QString);
    QPixmap takeSnapshot();
    int cFNumberToCInt(CFNumberRef input);
    QString cFStringToQString(CFStringRef s);

private slots:
     void iconActivated(QSystemTrayIcon::ActivationReason reason);
     void checkTimeout();
     void on_pushButton_clicked();
     void on_pushButtonRefreshList_clicked();
     void on_pushButtonAbout_clicked();
     void on_pushButtonFTPSave_clicked();
     void stateFTPChanged(int);
     void on_checkBox_stateChanged(int );
     void on_spinBox_valueChanged(int );
     void itsAboutTime();
     void stateFTPFinished(int, bool);
     void stateFTPStarted(int);
     void on_pushButton_2_clicked();
     void on_checkBox_clicked(bool checked);
     void on_horizontalSlider_sliderMoved(int position);
     void on_checkBoxSave_clicked(bool checked);
     void on_checkBoxCompareBeforeUpload_clicked(bool checked);
     void on_checkBoxFTP_clicked(bool checked);
     void on_checkBox_2_clicked(bool checked);
     void on_pushButtonNetBrowse_clicked();
};

#endif // MAINWINDOW_H