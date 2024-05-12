// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Fk.RoomElement

Item {
  id: root
  anchors.fill: parent
  property var extra_data: ({})

  signal finish()

  Flickable {
    height: parent.height
    width: generalButtons.width
    anchors.centerIn: parent
    contentHeight: generalButtons.height
    ScrollBar.vertical: ScrollBar {}
    ColumnLayout {
      id: generalButtons
      Repeater {
        model: ListModel {
          id: glist
        }

        ColumnLayout {
          Text {
            color: "#E4D5A0"
            text: luatr(gname)
          }
          GridLayout {
            columns: 6

            Repeater {
              model: lcall("GetSameGenerals", gname)

              GeneralCardItem {
                name: modelData
                selectable: true

                onClicked: {
                  const idx = extra_data.cards.findIndex(card => card === gname);

                  extra_data.cards[idx] = modelData;
                  root.finish();
                }
              }
            }
          }
        }
      }
    }
  }

  onExtra_dataChanged: {
    if (!extra_data.cards) return;
    for (let i = 0; i < extra_data.cards.length; i++) {
      glist.set(i, { gname: extra_data.cards[i] });
    }
  }
}
