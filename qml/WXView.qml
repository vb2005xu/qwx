// Copyright (C) 2014 - 2015 Leslie Zhai <xiang.zhai@i-soft.com.cn>

import QtQuick 2.2
import QtQuick.Controls 1.1
import cn.com.isoft.qwx 1.0
import "global.js" as Global

Item {
    id: wxView
    width: parent.width; height: parent.height

    ListModel {                                                                    
        id: wxListModel                                                          
        Component.onCompleted: {                                                   
            wxListModel.remove(0)                                          
        }                                                                          
                                                                                   
        ListElement { mUserName: ""; mNickName: ""; mContent: "" } 
    }

    Component.onCompleted: {
        Global.wxView = wxView;
        
        for (var i = 0; i < Global.initContactList.length; i++) {
            wxListModel.append({"mUserName": Global.initContactList[i].userName, 
                                "mNickName": Global.initContactList[i].nickName, 
                                "mContent": ""});
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

    function doNewMsg() 
    {
        if (Global.v2) {
            getMsgObj.postV2(Global.uin, Global.sid, Global.skey, Global.syncKey);
        } else {
            getMsgObj.post(Global.uin, Global.sid, Global.skey, Global.syncKey);
        }
    }

    SendMsg {
        id: sendMsgObj
    }

    GetMsg {
        id: getMsgObj
        onSyncKeyChanged: {
            if (getMsgObj.syncKey.length == 0) {
                rootWindowStackView.clear(); 
                rootWindowStackView.push({item: Qt.resolvedUrl("SplashView.qml")});
                return;
            }
            Global.syncKey = getMsgObj.syncKey;
        }
        onNoMsg: {
            rootWindow.title = "微信Qt前端";
        }
        onNewMsg: {
            rootWindow.title = "微信Qt前端 - 有新消息";
            var isExist = false;
            for (var i = 0; i < wxListModel.count; i++) {
                var userName = wxListModel.get(i).mUserName
                if (userName == fromUserName || 
                    userName == toUserName) {
                    isExist = true;
                    wxListModel.get(i).mContent = content;
                    wxListModel.move(i, 0, 1);
                    break;
                }
            }

            if (isExist == false) {
                if (Global.loginUserName == fromUserName) {
                    wxListModel.insert(0, {"mUserName": toUserName, 
                            "mNickName": contactObj.getNickName(toUserName)});
                } else {
                    wxListModel.insert(0, {"mUserName": fromUserName, 
                            "mNickName": contactObj.getNickName(fromUserName)});
                }
            }

            if (Global.isAway) {
                if (Global.v2) {
                    sendMsgObj.sendV2(Global.uin,
                            Global.sid,                                          
                            Global.skey,
                            Global.deviceId, 
                            toUserName,                                 
                            fromUserName,                                   
                            contactObj.getNickName(Global.loginUserName) + "不在，请在滴声音后留言 ;)",
                            Global.syncKey)                                      
                } else {
                    sendMsgObj.send(Global.uin,
                                Global.sid,
                                Global.skey,
                                Global.deviceId,
                                toUserName,
                                fromUserName,
                                contactObj.getNickName(Global.loginUserName) + "不在，请在滴声音后留言",
                                Global.syncKey)
                }
            }
        }
    }

    ListView {
        id: wxListView
        model: wxListModel
        anchors.fill: parent

        delegate: Item {
            width: parent.width; height: 60

            HeadImg {
                id: headImgObj
                v2: Global.v2
                userName: mUserName
                onFilePathChanged: {
                    headImage.imageSource = headImgObj.filePath
                }
            }

            CircleImage {
                id: headImage
                width: 42; height: 42
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
            }

            Text {
                id: nickNameText
                text: mNickName
                font.pixelSize: 13
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.left: headImage.right
                anchors.leftMargin: 11
            }

            Text {
                text: mContent
                font.pixelSize: 11
                anchors.top: nickNameText.bottom
                anchors.topMargin: 6
                anchors.left: nickNameText.left
            }

            Rectangle {
                width: parent.width; height: 1
                color: "#dadada"
            }

            MouseArea {                                                        
                anchors.fill: parent                                           
                onClicked: {                                                   
                    navigatorStackView.push({                                  
                        item: Qt.resolvedUrl("ChatView.qml"),                  
                        properties: {                                          
                            fromUserName: Global.loginUserName,
                            toUserName: mUserName,                    
                            toNickName: mNickName}})                  
                }                                                              
            }
        }
    }
}
