#include "mainwindow.h"
#include "ui_mainwindow.h"

bool running = false;
int freq = 1000;
double frames = 0;
double framesSave = 0;
bool commandRunning = false;
bool able= true;
bool useFTP = false;
int ftpTimeout = 1000;
bool working = false;

QSystemTrayIcon *trayIcon;
QSettings settings(QString("Snappy.ini"), QSettings::IniFormat);
QFtp *ftp = new QFtp();
QString rememberFilename("");
QTimer *timer = new QTimer();
QTimer *ftpTimeOutTimer = new QTimer();
QString framesLabel("Label");
QList<QString> savePixmap;
QList<uint> savePixmapData;

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    QVariant firstRun = settings.value("set/firstRun");
    if (!(firstRun == "false")) {
        QMessageBox welcome;
        welcome.setIcon(QMessageBox::Information);
        welcome.setText(tr("Welcome to Snappy. This is the first time you are running this application. Please setup your FTP details!"));
        welcome.exec();
        settings.setValue("set/firstRun", "false");
        settings.setValue("set/freq", 1000);
    } else {
        ui->lineEditFTPHost->setText(settings.value("ftp/host").value<QString>());
        ui->lineEditFTPPassword->setText(settings.value("ftp/pw").value<QString>());
        ui->lineEditFTPUsername->setText(settings.value("ftp/usr").value<QString>());
        ui->lineEditFTPPath->setText(settings.value("ftp/path").value<QString>());
        ui->lineEdit->setText(settings.value("set/netloc").value<QString>());
        ui->checkBox_2->setChecked(settings.value("set/net").value<bool>());

        useFTP = settings.value("set/ftp").value<bool>();
        ui->checkBoxFTP->setChecked(useFTP);
        ui->spinBoxFTPPort->setValue(settings.value("ftp/port").value<int>());
        ftpTimeout = settings.value("ftp/timeout").value<int>();
        if (settings.value("ftp/port").value<int>() == 0) ui->spinBoxFTPPort->setValue(21);
        ui->horizontalSlider->setValue(settings.value("set/quality").value<int>());
        connect(timer, SIGNAL(timeout()), this, SLOT(itsAboutTime()));

        ftp = new QFtp();
        connect(ftp,SIGNAL(stateChanged(int)), this, SLOT(stateFTPChanged(int)));
        connect(ftp,SIGNAL(commandFinished(int, bool)), this, SLOT(stateFTPFinished(int, bool)));
        connect(ftp,SIGNAL(commandStarted(int)), this, SLOT(stateFTPStarted(int)));
        if (useFTP) {
            ftp->connectToHost(ui->lineEditFTPHost->text(),ui->spinBoxFTPPort->value());
            while (commandRunning) qApp->processEvents();
            ftp->login(ui->lineEditFTPUsername->text(),ui->lineEditFTPPassword->text());
            while (commandRunning) qApp->processEvents();
            ftp->setTransferMode(QFtp::Passive);
            while (commandRunning) qApp->processEvents();
            ftp->cd(ui->lineEditFTPPath->text());
        }
        running = settings.value("set/enableRun").value<bool>();
        frames = settings.value("set/frames").value<double>();
        freq = settings.value("set/freq").value<int>();
        ui->checkBox->setChecked(running);
        ui->spinBox->setValue(freq);
        timer->setInterval(freq);
        ui->checkBoxSave->setChecked(settings.value("set/save").value<bool>());
        ui->checkBoxCompareBeforeUpload->setChecked(settings.value("set/compare").value<bool>());
        if (running) timer->start();
        framesSave = frames;
    }

    QIcon *icon = new QIcon(":new/prefix1/ic");
    trayIcon = new QSystemTrayIcon(*icon,this);
    trayIcon->setParent(this);
    trayIcon->show();
    connect(trayIcon, SIGNAL(activated(QSystemTrayIcon::ActivationReason)),
                      this, SLOT(iconActivated(QSystemTrayIcon::ActivationReason)));
}

void MainWindow::stateFTPStarted(int yepp) {
    commandRunning = true;
}

void MainWindow::stateFTPFinished(int yep, bool boolie) {
    commandRunning = false;

    if (boolie || ftp->error()){
        timer->stop();
        ftp->disconnect();
        ui->statusBar->showMessage(ftp->errorString());
    }
    if (!boolie) able=true;
}

int MainWindow::cFNumberToCInt(CFNumberRef input)
{
        if (input == NULL)
                return 0;
        int output;
        CFNumberGetValue(input, kCFNumberIntType, &output);
        return output;
}

void MainWindow::checkTimeout() {
    if (ftp->state() == QFtp::Connecting) {
        ui->checkBox->setEnabled(false);
        timer->stop();
        ftp->disconnect();
        while (commandRunning) qApp->processEvents();
        qApp->quit();
    }
}

void MainWindow::stateFTPChanged(int state) {
    if (state == QFtp::LoggedIn){
        ui->statusBar->showMessage(tr("FTP is now connected!"));
    } else if (state == QFtp::Connecting) {
        ui->statusBar->showMessage(tr("Connecting to FTP ... (Please check your Details.)"));
        QTimer::singleShot(ftpTimeout,this,SLOT(checkTimeout()));
    } else if (state == QFtp::Unconnected) {
        timer->stop();
        ftp->disconnect();
        ui->statusBar->showMessage(tr("NOT connected to FTP! Reconnecting ..."));

        ftp->disconnect();
        while (commandRunning) qApp->processEvents();
        ftp = new QFtp();
        connect(ftp,SIGNAL(stateChanged(int)), this, SLOT(stateFTPChanged(int)));
        connect(ftp,SIGNAL(commandFinished(int, bool)), this, SLOT(stateFTPFinished(int, bool)));
        connect(ftp,SIGNAL(commandStarted(int)), this, SLOT(stateFTPStarted(int)));

        bool test = ftp->connectToHost(ui->lineEditFTPHost->text(),ui->spinBoxFTPPort->value());
        while (commandRunning) qApp->processEvents();
        ftp->login(ui->lineEditFTPUsername->text(),ui->lineEditFTPPassword->text());
        while (commandRunning) qApp->processEvents();
        ftp->setTransferMode(QFtp::Passive);
        while (commandRunning) qApp->processEvents();
        ftp->cd(ui->lineEditFTPPath->text());
        if (test)timer->start();
    }
}

MainWindow::~MainWindow() {
    delete ui;
}

void MainWindow::itsAboutTime() {
    if (!able || working) {
        ui->statusBar->showMessage(ui->statusBar->currentMessage() + tr("."));
        return;
    }

    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    settings.setValue("set/frames", frames);
    able = false;
    working = true;
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    CFIndex windowNum = CFArrayGetCount(windowList);
    QMessageBox msg;
    msg.setIcon(QMessageBox::Information);

    QPixmap snap;
    CGImageRef windowImage;
    QString infotxt;
    for (int i = 0; i < (int)windowNum; i++) {
        able = false;
        CFDictionaryRef info = (CFDictionaryRef)CFArrayGetValueAtIndex(windowList, i);
        CFNumberRef currentPID = (CFNumberRef)CFDictionaryGetValue(info, kCGWindowOwnerPID);
        CFNumberRef currentWindowNumber = (CFNumberRef)CFDictionaryGetValue(info, kCGWindowNumber);
        CFStringRef currentTitle = (CFStringRef)CFDictionaryGetValue(info, kCGWindowName);

        long output;
        CFNumberGetValue(currentWindowNumber, kCFNumberLongType, &output);
        long outputPID;
        CFNumberGetValue(currentPID, kCFNumberLongType, &outputPID);
        CFDictionaryRef bounds = (CFDictionaryRef)CFDictionaryGetValue(info, kCGWindowBounds);
        CGRect *temp = new CGRect;
        CGRectMakeWithDictionaryRepresentation(bounds, temp);
        NSBitmapImageRep *this_bmap = 0;
        NSAutoreleasePool* loopPool = [NSAutoreleasePool new];
        CGImageRef windowImage = CGWindowListCreateImage(*temp, kCGWindowListOptionIncludingWindow,
          (uint32_t) output, kCGWindowImageDefault);

        this_bmap = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
        void *pixels1 = [this_bmap bitmapData];
        snap = QPixmap::fromMacCGImageRef(windowImage);
        [this_bmap release];
        CGImageRelease(windowImage);
        [loopPool release];

        if (ui->checkBoxCompareBeforeUpload->isChecked()) {
          uint snapHash = qHash(snap.pixmapData());
          if (((int)framesSave - (int)frames) % 20 == 0) {
            savePixmap.clear();
            savePixmapData.clear();
          }
          if (!savePixmap.contains(cFStringToQString(currentTitle))) {
            savePixmap.append(cFStringToQString(currentTitle));
            savePixmapData.append(snapHash);
            if (ui->checkBoxSave->isChecked()) snap.save(QString(QString("win%1").arg(i) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
            if (ui->checkBox_2->isChecked() && !ui->lineEdit->text().isEmpty()) snap.save(QString(QString("%2/win%1").arg(i).arg(ui->lineEdit->text()) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
            QByteArray bar;
            QBuffer buff(&bar);
            buff.open(QBuffer::ReadWrite);
            snap.save(&buff, "JPG", ui->horizontalSlider->value());
            rememberFilename = QString(QString("win%1").arg(i) + tr(".jpg"));
            ftp->put(bar, QString("win%1").arg(i) + tr(".jpg"),QFtp::Binary);
            while (commandRunning) qApp->processEvents();
          } else {
            int indx = savePixmap.indexOf(cFStringToQString(currentTitle));
            if (!(savePixmapData.at(indx) == snapHash)) {
              savePixmap.removeAt(indx);
              savePixmapData.removeAt(indx);
              savePixmap.append(cFStringToQString(currentTitle));
              savePixmapData.append(snapHash);

              if (ui->checkBoxSave->isChecked()) snap.save(QString(QString("win%1").arg(i) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
              if (ui->checkBox_2->isChecked() && !ui->lineEdit->text().isEmpty()) snap.save(QString(QString("%2/win%1").arg(i).arg(ui->lineEdit->text()) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
              QByteArray bar;
              QBuffer buff(&bar);
              buff.open(QBuffer::ReadWrite);
              snap.save(&buff, "JPG", ui->horizontalSlider->value());
              rememberFilename = QString(QString("win%1").arg(i) + tr(".jpg"));
              ftp->put(bar, QString("win%1").arg(i) + tr(".jpg"),QFtp::Binary);
              while (commandRunning) qApp->processEvents();
            } else {
              // Image has not changed.
            }
          }
        } else {
          if (ui->checkBoxSave->isChecked()) snap.save(QString(QString("win%1").arg(i) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
          if (ui->checkBox_2->isChecked() && !ui->lineEdit->text().isEmpty()) snap.save(QString(QString("%2/win%1").arg(i).arg(ui->lineEdit->text()) + tr(".jpg")), "JPG", ui->horizontalSlider->value());
          QByteArray bar;
          QBuffer buff(&bar);
          buff.open(QBuffer::ReadWrite);
          snap.save(&buff, "JPG", ui->horizontalSlider->value());
          rememberFilename = QString(QString("win%1").arg(i) + tr(".jpg"));
          ftp->put(bar, QString("win%1").arg(i) + tr(".jpg"),QFtp::Binary);
          while (commandRunning) qApp->processEvents();
        }
        OSErr err;
        ProcessSerialNumber psn;
        CFStringRef result;
        QString processName("N/A");
        err = GetProcessForPID((pid_t)outputPID,&psn);
        if (err == noErr) {
          CopyProcessName(&psn, &result);
          processName = cFStringToQString(result);
        }
        infotxt += (QString("Window#: %1;; Title: %2;; WindowID: %3;; PID: %4;; SnapTime: %5;; PName: %6\n").arg(i).arg(cFStringToQString(currentTitle)).arg(output).arg(outputPID).arg(QTime::currentTime().toString("hh:mm:ss.zzz")).arg(processName));
        qApp->processEvents();
    }
    CFRelease(windowList);
    QByteArray bartxt;
    QBuffer bufftxt(&bartxt);
    bufftxt.open(QBuffer::ReadWrite);
    if (ui->checkBoxSave->isChecked()) {
      QFile localTxt(QString("info.txt"));
      localTxt.open(QIODevice::WriteOnly | QIODevice::Text);
      QTextStream localTxtOut(&localTxt);
      localTxtOut << infotxt.toAscii();
    }
    if (ui->checkBox_2->isChecked()) {
      QFile netTxt(QString(QString("%1/info.txt").arg(ui->lineEdit->text())));
      netTxt.open(QIODevice::WriteOnly | QIODevice::Text);
      QTextStream netTxtOut(&netTxt);
      netTxtOut << infotxt.toAscii();
    }
    ftp->put(infotxt.toAscii(), QString("info.txt"),QFtp::Binary);
    while (commandRunning) qApp->processEvents();
    framesLabel = QString("Frames processed: %1 ").arg(frames);
    ui->statusBar->showMessage(framesLabel);
    frames++;
    [pool release];
    working = false;
    able = true;
}

void MainWindow::iconActivated(QSystemTrayIcon::ActivationReason reason) {
    switch (reason) {
      case QSystemTrayIcon::Trigger:
          if (!this->isVisible()) {
            this->show();on_pushButtonRefreshList_clicked();
          } else {
            this->hide();
          }
          break;
      case QSystemTrayIcon::DoubleClick:
          break;
      default:
    }

}
int MainWindow::showMessage(QString title, QString plainText) {
    QMessageBox error;
    error.setIcon(QMessageBox::Warning);
    error.setText(plainText);
    error.setWindowTitle(title);
    error.exec();
}

void MainWindow::on_pushButton_clicked() {
    qApp->quit();
}
QString MainWindow::cFStringToQString(CFStringRef s) {
    QString result;
    if (s != NULL) {
      CFIndex length = 2 * (CFStringGetLength(s) + 1);
      char* buffer = new char[length];
      if (CFStringGetCString(s, buffer, length, kCFStringEncodingUTF8)) {
        result = QString::fromUtf8(buffer);
      } else {
        qWarning("CFString conversion failed.");
      }
      delete buffer;
    }
    return result;
}

QPixmap MainWindow::takeSnapshot() {
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    CFIndex windowNum = CFArrayGetCount(windowList);
    QMessageBox msg;
    msg.setIcon(QMessageBox::Information);
    QString conc1("Number of open windows: %1.\n");

    QPixmap *snap = new QPixmap();
    CGImageRef windowImage;
    for (int i=0;i<(int)windowNum;i++) {
        CFDictionaryRef info = (CFDictionaryRef)CFArrayGetValueAtIndex(windowList, i);
        CFNumberRef currentWindowNumber = (CFNumberRef)CFDictionaryGetValue(info, kCGWindowNumber);
        CFStringRef currentTitle = (CFStringRef)CFDictionaryGetValue(info, kCGWindowName);
        if (cFStringToQString(currentTitle) != "") {
          CFDictionaryRef bounds = (CFDictionaryRef)CFDictionaryGetValue(info, kCGWindowBounds);
          long output;
          CFNumberGetValue(currentWindowNumber, kCFNumberLongType, &output);
          CGRect *temp = new CGRect;
          CGRectMakeWithDictionaryRepresentation(bounds, temp);
          windowImage = CGWindowListCreateImage(*temp, kCGWindowListOptionIncludingWindow,(uint32_t)output, kCGWindowImageDefault);
          snap = new QPixmap(QPixmap::fromMacCGImageRef(windowImage));
          snap->save(QString("./") + cFStringToQString(currentTitle) + QString(".png"),"PNG", 100); // Quality between 0 and 100!
        }
        qApp->processEvents();
    }
    [windowImage autorelease];
    msg.setText(conc1 + QString("\nNumber of open windows: %1.\nI will now take a snapshot of the window on top.").arg((int)windowNum));
    msg.exec();
    return *snap;
}

void MainWindow::on_pushButtonRefreshList_clicked() {
    ui->plainTextEdit->clear();
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    CFIndex windowNum = CFArrayGetCount(windowList);
    for (int i=0;i<(int)windowNum;i++) {
      CFDictionaryRef info = (CFDictionaryRef)CFArrayGetValueAtIndex(windowList, i);
      CFNumberRef currentPID = (CFNumberRef)CFDictionaryGetValue(info, kCGWindowOwnerPID);
      CFNumberRef currentWindowNumber = (CFNumberRef)CFDictionaryGetValue(info, kCGWindowNumber);
      CFStringRef currentTitle = (CFStringRef)CFDictionaryGetValue(info, kCGWindowName);
      long output;
      CFNumberGetValue(currentWindowNumber, kCFNumberLongType, &output);
      long outputPID;
      CFNumberGetValue(currentPID, kCFNumberLongType, &outputPID);

      OSErr err;
      ProcessSerialNumber psn;
      CFStringRef result;
      QString processName("N/A");
      err = GetProcessForPID((pid_t)outputPID,&psn);
      if (err == noErr) {
        CopyProcessName(&psn, &result);
        processName = cFStringToQString(result);
      }
      ui->plainTextEdit->appendPlainText(QString("Window#: %1; Title: %2; WindowID: %3; PID: %4; PName: %5\n").arg(i).arg(cFStringToQString(currentTitle)).arg(output).arg(outputPID).arg(processName));
    }
}

void MainWindow::on_pushButtonAbout_clicked() {
    QMessageBox about;
    about.setIcon(QMessageBox::Information);
    about.setText(tr("In order to autostart this application when you turn on your Mac, follow these steps:\nTop left Apple icon >> 'System Preferences...' >> Accounts >> Click on your username >> Click on 'Login Items' (Next to 'Password') >> Click the [+] and navigate to the executable of Snappy. Done.\nTell me what to write here plz."));
    about.exec();
}

void MainWindow::on_pushButtonFTPSave_clicked() {
    settings.setValue("ftp/host", ui->lineEditFTPHost->text());
    settings.setValue("ftp/pw", ui->lineEditFTPPassword->text());
    settings.setValue("ftp/usr", ui->lineEditFTPUsername->text());
    settings.setValue("ftp/path", ui->lineEditFTPPath->text());
    settings.setValue("ftp/port", ui->spinBoxFTPPort->value());
    QMessageBox good;
    good.setIcon(QMessageBox::Warning);
    good.setText(tr("Details have been saved.\nMake sure the path you just specified is available at the FTP Server. It might be necessary to create a directory.\nWARNING: The password is NOT stored encrypted!!"));
    good.exec();
}

void MainWindow::on_checkBox_stateChanged(int booly) {
    if (ui->checkBox->isChecked()) {
      ftp->disconnect();
      settings.setValue("set/enableRun", true);
      running = true;
      timer->stop();
      
      ftp = new QFtp();
      ftp->connectToHost(ui->lineEditFTPHost->text(),ui->spinBoxFTPPort->value());
      while (commandRunning) qApp->processEvents();
      ftp->login(ui->lineEditFTPUsername->text(),ui->lineEditFTPPassword->text());
      while (commandRunning) qApp->processEvents();
      ftp->setTransferMode(QFtp::Passive);
      while (commandRunning) qApp->processEvents();
      ftp->cd(ui->lineEditFTPPath->text());
      running = settings.value("set/enableRun").value<bool>();
      frames = settings.value("set/frames").value<double>();
      freq = settings.value("set/freq").value<int>();
      ui->checkBox->setChecked(running);
      ui->spinBox->setValue(freq);
      ui->checkBoxSave->setChecked(settings.value("set/save").value<int>());
      ui->checkBoxCompareBeforeUpload->setChecked(settings.value("set/compare").value<int>());
      timer->setInterval(freq);
      timer->start();
    } else {
      settings.setValue("set/enableRun", false);
      running = false;
      timer->stop();
    }
}

void MainWindow::on_spinBox_valueChanged(int value) {
    settings.setValue("set/freq", value);
    timer->setInterval(value);
    freq = value;
}

void MainWindow::on_pushButton_2_clicked() {
    this->hide();
}

void MainWindow::on_checkBox_clicked(bool checked) {
}

void MainWindow::on_horizontalSlider_sliderMoved(int position) {
    settings.setValue("set/quality", position);
}

void MainWindow::on_checkBoxSave_clicked(bool checked) {
    settings.setValue("set/save", checked);
}

void MainWindow::on_checkBoxCompareBeforeUpload_clicked(bool checked) {
    settings.setValue("set/compare", checked);
}

void MainWindow::on_checkBoxFTP_clicked(bool checked) {
    settings.setValue("set/ftp", checked);
    useFTP = checked;
}

void MainWindow::on_checkBox_2_clicked(bool checked) {
    settings.setValue("set/net", checked);
    settings.setValue("set/netloc", ui->lineEdit->text());
}

void MainWindow::on_pushButtonNetBrowse_clicked() {
    ui->lineEdit->setText(QFileDialog::getExistingDirectory(this, tr("Browse for Path"), ui->lineEdit->text()));
    settings.setValue("set/netloc", ui->lineEdit->text());
}