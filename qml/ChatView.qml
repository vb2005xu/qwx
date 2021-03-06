// Copyright (C) 2014 - 2015 Leslie Zhai <xiang.zhai@i-soft.com.cn>

import QtQuick 2.2
import QtQuick.Controls 1.1
import cn.com.isoft.qwx 1.0
import "global.js" as Global

Rectangle {
    id: chatView
    width: parent.width; height: parent.height
    color: "white"

    property string fromUserName
    property string toUserName
    property string toNickName

    function moveToTheEnd() 
    {
        chatListView.positionViewAtEnd()
    }

    Component.onCompleted: {
        Global.chatView = chatView
    }

    XiaoDouBi {
        id: xiaodoubiObj
        onContentChanged: {
            if (!Global.isRobot) {
                return
            }
            if (Global.v2) {
                sendMsgObj.sendV2(Global.uin,
                            Global.sid,                                          
                            Global.skey,
                            Global.deviceId, 
                            chatView.fromUserName,                                 
                            chatView.toUserName,                                   
                            content,                                 
                            Global.syncKey)                                      
            } else {
                sendMsgObj.send(Global.uin,
                                Global.sid,
                                Global.skey,
                                Global.deviceId,
                                chatView.fromUserName,
                                chatView.toUserName,
                                content,
                                Global.syncKey)
            }

            chatListModel.append({"content": content,                
                                  "curUserName": chatView.fromUserName})           
            moveToTheEnd()
        }
    }

    Contact {                                                                      
        id: contactObj                                                             
        Component.onCompleted: {                                                   
            if (Global.v2) {                                                       
                contactObj.postV2()                                                
            } else {                                                               
                contactObj.post()                                                  
            }                                                                      
        }                                                                          
    }

    Process {
        id: processObj
        program: "notify-send"
    }

    function doNewMsg()                                                            
    {                                                                              
        if (Global.v2) {                                                           
            getMsgObj.postV2(Global.uin, Global.sid, Global.skey, Global.syncKey);
        } else {                                                                   
            getMsgObj.post(Global.uin, Global.sid, Global.skey, Global.syncKey);
        }                                                                          
    }

    GetMsg {                                                                       
        id: getMsgObj
        fromUserName: chatView.fromUserName
        toUserName: chatView.toUserName
        onNoMsg: {
            rootWindow.title = "微信Qt前端";
        }
        onReceived: {
            rootWindow.title = "微信Qt前端 - 有新消息";
            if (content == "小逗比退下" || content == "robot away") {
                Global.isRobot = false;
            } else if (content == "小逗比出来" || content == "robot come") {
                Global.isRobot = true;
            }
            chatListModel.append({"content": content, "curUserName": userName});
            moveToTheEnd();
            if (Global.isRobot) {
                xiaodoubiObj.get(content);
            }
        }
        onNewMsg: {
            if (Global.isRobot) {
                xiaodoubiObj.get(content)
            }
            if (fromUserName != chatView.fromUserName || 
                fromUserName != chatView.toUserName) {
                var nickName = ""
                if (chatView.fromUserName == fromUserName) {
                    nickName = contactObj.getNickName(toUserName)
                } else {
                    nickName = contactObj.getNickName(fromUserName)
                }
                processObj.arguments = [nickName, content, '--icon=dialog-information', '-t', '3000']
                processObj.start()
            }
        }
    }                                                                              

    SendMsg {
        id: sendMsgObj
    }

    ListModel {
        id: chatListModel
        Component.onCompleted: {
            chatListModel.clear()
        }

        ListElement { content: ""; curUserName: "" }
    }

    ListView {
        id: chatListView
        model: chatListModel
        width: parent.width; height: parent.height - chatHeader.height - 
        sendMsgTextField.height
        anchors.top: chatHeader.bottom
        spacing: 10
        delegate: Item {
            width: parent.width 
            height: chatText.contentHeight < fromUserHeadImage.height ? fromUserHeadImage.height : chatText.contentHeight
   
            HeadImg {
                id: fromUserHeadImgObj 
                userName: curUserName 
                onFilePathChanged: { 
                    fromUserHeadImage.imageSource = fromUserHeadImgObj.filePath 
                }
            }

            CircleImage {
                id: fromUserHeadImage
                width: 42; height: 42
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.top: parent.top
            }

            Text {
                id: chatText
                text: content
                width: parent.width - fromUserHeadImage.width - 30 
                wrapMode: Text.WordWrap
                font.pixelSize: 11
                anchors.left: fromUserHeadImage.right
                anchors.leftMargin: 10
            }
        }
    }

    Rectangle {                                                            
        id: chatHeader                                                
        width: parent.width; height: 58                                    
        anchors.top: parent.top                                            
        color: "#20282a"                                                   

        Image {
            id: backImage
            source: "../images/back.png"
            width: 36; height: 36
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 19

            MouseArea {
                anchors.fill: parent
                onClicked: { navigatorStackView.pop(); }
            }
        }

        Text {                                                             
            text: chatView.toNickName
            font.pixelSize: 22                                             
            anchors.verticalCenter: parent.verticalCenter                  
            anchors.left: backImage.right
            anchors.leftMargin: 19                                         
            color: "white"                                                 
        }                                                                  
    }

    TextField {
        id: sendMsgTextField
        width: parent.width - sendButton.width
        anchors.bottom: parent.bottom
    }

    Button {
        id: sendButton
        text: "发送"
        anchors.top: sendMsgTextField.top
        anchors.right: parent.right
        onClicked: {
            if (Global.v2) {
                sendMsgObj.sendV2(Global.uin,
                            Global.sid, 
                            Global.skey,
                            Global.deviceId, 
                            chatView.fromUserName, 
                            chatView.toUserName, 
                            sendMsgTextField.text, 
                            Global.syncKey);
            } else {
                sendMsgObj.send(Global.uin,
                                Global.sid,
                                Global.skey,
                                Global.deviceId,
                                chatView.fromUserName,
                                chatView.toUserName,
                                sendMsgTextField.text,
                                Global.syncKey);
            }
            chatListModel.append({"content": sendMsgTextField.text, 
                                  "curUserName": chatView.fromUserName});
            if (sendMsgTextField.text == "away") {
                Global.isAway = true;                     
            } else if (sendMsgTextField.text == "back") {
                Global.isAway = false;
            } else if (sendMsgTextField.text == "小逗比出来" || 
                       sendMsgTextField.text == "robot come") {
                Global.isRobot = true;
                xiaodoubiObj.get(sendMsgTextField.text);
            } else if (sendMsgTextField.text == "小逗比退下" || 
                       sendMsgTextField.text == "robot away") {
                Global.isRobot = false;
            } else if (Global.isRobot) {
                xiaodoubiObj.get(sendMsgTextField.text);
            }
            sendMsgTextField.text = "";
            moveToTheEnd();
        }
    }
}
