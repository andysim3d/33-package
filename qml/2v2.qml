import QtQuick
import QtQuick.Layouts
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var friend_cards: []
  property var my_cards: []
  property string friend_recommend
  property string friend_not_determ: ""
  property string friend_selected: ""
  property string my_recommend
  property string selected
  property bool initial: true
  width: 70 + 100 * my_cards.length
  height: 360

  ColumnLayout {
    id: cardView
    anchors.fill: parent
    anchors.margins: 20
    anchors.bottomMargin: 50
    anchors.topMargin: 30

    RowLayout {
      spacing: 8

      Rectangle {
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: "队友"
          color: "white"
          font.family: fontLibian.name
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Repeater {
        model: friend_cards

        GeneralCardItem {
          name: modelData
          selectable: root.friend_selected == ""
          onClicked: {
            if (!selectable) return;
            if (root.friend_recommend == modelData) {
              root.friend_recommend = "";
            } else {
              root.friend_recommend = modelData;
            }
            ClientInstance.notifyServer("PushRequest", "updatemini,recommend," + root.friend_recommend);
          }

          onRightClicked: {
            roomScene.startCheat("GeneralDetail", { generals: [modelData] });
          }

          Image {
            source: AppPath + "/packages/gamemode/image/determ.png"
            visible: friend_selected == modelData
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }

          Image {
            source: AppPath + "/packages/gamemode/image/not_determ.png"
            visible: friend_not_determ == modelData
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }

          Image {
            source: AppPath + "/packages/gamemode/image/recommend2.png"
            visible: friend_recommend == modelData
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }
        }
      }
    }

    RowLayout {
      spacing: 8

      Rectangle {
        color: "#6B5D42"
        width: 20
        height: 100
        radius: 5

        Text {
          anchors.fill: parent
          width: 20
          height: 100
          text: "你"
          color: "white"
          font.family: fontLibian.name
          font.pixelSize: 18
          style: Text.Outline
          wrapMode: Text.WordWrap
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Repeater {
        model: my_cards

        GeneralCardItem {
          name: modelData
          selectable: true
          chosenInBox: root.selected == name
          selected: root.selected == name
          onClicked: {
            if (!selectable) return;
            if (root.selected == name) {
              root.selected = "";
            } else {
              root.selected = name;
            }
            ClientInstance.notifyServer("PushRequest", "updatemini,preselect," + root.selected);
          }

          onRightClicked: {
            if (config.enableFreeAssign)
              roomScene.startCheat("FreeAssign", { card: this });
          }

          Image {
            source: AppPath + "/packages/gamemode/image/recommend.png"
            visible: my_recommend == modelData
            anchors.horizontalCenter: parent.horizontalCenter
            y: 90
            scale: 0.75
          }
        }
      }
    }
  }

  Item {
    id: buttonArea
    width: parent.width
    height: 40
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 5

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      MetroButton {
        id: convertBtn
        // visible: !convertDisabled
        enabled: false
        text: luatr("Same General Convert")
        onClicked: {
          cheatLoader.sourceComponent = Qt.createComponent("./SameConvertFrame.qml");
          cheatLoader.item.extra_data = { cards: my_cards };
          cheatLoader.item.finish.connect(root.my_cardsChanged);
          cheatDrawer.open();
        }
      }

      MetroButton {
        id: fightButton
        text: luatr("Fight")
        width: 120
        height: 35
        enabled: root.selected !== ""

        onClicked: {
          close();
          roomScene.state = "notactive";
          ClientInstance.notifyServer("PushRequest", "updatemini,select," + root.selected);
          ClientInstance.replyToServer("", JSON.stringify(root.selected));
        }
      }

      MetroButton {
        id: detailBtn
        enabled: root.selected !== ""
        text: luatr("Show General Detail")
        onClicked: roomScene.startCheat(
          "GeneralDetail",
          { generals: [root.selected] }
        );
      }
    }
  }

  function loadData(data) {
    root.title.text = ("你的座次是 %1 , 请选择")
      .arg(luatr("seat#" + roomScene.getPhoto(Self.id).seatNumber))
    root.friend_cards = data.friend;
    root.my_cards = data.me;

    for (let generalName of data.me) {
      if (lcall("GetSameGenerals", generalName).length > 0) {
        convertBtn.enabled = true;
        break;
      }
    }

    root.initial = false;
  }

  onMy_cardsChanged: {
    if (root.initial) {
      return;
    }

    ClientInstance.notifyServer("PushRequest", "updatemini,updateFriendCards," + my_cards.join("|"));
    if (root.selected && !my_cards.includes(root.selected)) {
      root.selected = "";
      ClientInstance.notifyServer("PushRequest", "updatemini,preselect," + root.selected);
    }
  }

  function updateData(data) {
    let [type, value] = data;
    value = value ?? "";
    if (type == "preselect") {
      friend_not_determ = value;
    } else if (type == "select") {
      friend_not_determ = "";
      friend_recommend = "";
      friend_selected = value;
    } else if (type == "recommend") {
      my_recommend = value;
    } else if (type == "updateFriendCards") {
      friend_cards = value.split("|");
    }
  }
}
