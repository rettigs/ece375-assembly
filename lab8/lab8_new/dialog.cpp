#include "dialog.h"
#include "ui_dialog.h"
#include <QPainter>
#include <QKeyEvent>

Dialog::Dialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::Dialog)
{
    ui->setupUi(this);
}

Dialog::~Dialog()
{
    delete ui;
}

void Dialog::paintEvent(QPaintEvent *event)
{
    //create a QPainter and pass a pointer to the device.
    //A paint device can be a QWidget, a QPixmap or a QImage
    QPainter painter(this);

    //a simple line
    painter.drawLine(1,1,100,100);

    //create a black pen that has solid line
    //and the width is 2.
    QPen myPen(Qt::black, 2, Qt::SolidLine);
    painter.setPen(myPen);
    painter.drawLine(100,100,100,1);

    //draw a point
    myPen.setColor(Qt::red);
    painter.drawPoint(110,110);
}

void Dialog::keyPressEvent(QKeyEvent *ev)
{
    printf("hi\n");
}

void Dialog::drawPoint(int x, int y)
{
    QPainter painter(this);
    QPen myPen(Qt::black, 2, Qt::SolidLine);
    myPen.setColor(Qt::red);
    painter.drawPoint(x,y);
}
