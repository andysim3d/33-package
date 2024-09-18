// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Pages
import Fk.RoomElement
import Qt5Compat.GraphicalEffects

GraphicsBox {
  id: root

  property list<string> generals: []
  property var selectedItem: []
  property int num : 1
  property string prompt : ""
  property list<int> my_selected: []
  property list<int> ur_selected: []


  title.text: Util.processPrompt(prompt)
  width: 620
  height: 370

  Flickable {
    id : cardArea
    height : 280
    width : 600
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.horizontalCenter: parent.horizontalCenter

    // for choose more than 12 cards
    contentHeight: gridLayout.implicitHeight
    ScrollBar.horizontal: ScrollBar {}
    flickableDirection: Flickable.VerticalFlick
    
    clip: true

    GridLayout {
      id : gridLayout
      columns : 6
      width: parent.width
      height: parent.height
      clip: true

      Repeater {
        id: generalRepeater
        model: generals

        delegate: GeneralCardItem {
          name: modelData
          selectable: !my_selected.includes(index) && !ur_selected.includes(index)

          onClicked: {
            if (!selectable || num == 0) return;

            if (chosenInBox) {
              selectedItem.splice(root.selectedItem.indexOf(index), 1);
              chosenInBox = false;
            } else {
              chosenInBox = true;
              root.selectedItem.push(index);
              if (selectedItem.length > num) {
                generalRepeater.itemAt(selectedItem[0]).chosenInBox = false;
                selectedItem.splice(0, 1);
              }
            }
            updateSelectable();
          }

          onRightClicked: {
            if (config.enableFreeAssign)
              roomScene.startCheat("FreeAssign", { card: this });
          }
          

        }
      }

    }
  }


  Item {
    id: buttonArea
    height: 40
    width: parent.width
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 10
    
    
    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 15

      MetroButton {
        id: convertBtn
        enabled: false
        text: luatr("Same General Convert")
        onClicked: {
          cheatLoader.sourceComponent = Qt.createComponent("./SameConvertFrame.qml");
          cheatLoader.item.extra_data = { cards: generals };
          cheatDrawer.open();
        }
      }

      MetroButton {
        id: buttonConfirm
        width: 120
        text: luatr("OK")
        enabled: selectedItem.length == num

        onClicked: {
          close();
          roomScene.state = "notactive";
          ClientInstance.replyToServer("", JSON.stringify(
            { ids : selectedItem, generals : selectedItem.map(id => generalRepeater.itemAt(id).name) }
          ));
        }
      }

      MetroButton {
        id: buttonDetail
        enabled: selectedItem.length
        text: luatr("Show General Detail")
        onClicked: roomScene.startCheat(
          "GeneralDetail",
          { generals: selectedItem.map(id => generalRepeater.itemAt(id).name) }
        );
      }

    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = selectedItem.length == num;
    buttonDetail.enabled = selectedItem.length;
  }

  function loadData(data) {
    [generals, num, my_selected, ur_selected, prompt] = data;
    for (var i = 0; i < generals.length; i++) {
      let generalName = generals[i]
      if (!my_selected.includes(i) && !ur_selected.includes(i) && lcall("GetSameGenerals", generalName).length) {
        convertBtn.enabled = true;
        break;
      }
    }
  }
}
