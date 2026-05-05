import QtQuick
import Quickshell
import Quickshell.Io
import "WindowRegistry.js" as LayoutMath 

Item {
    id: scaler_root
    visible: false

    property real currentWidth: 1920.0
    property real currentHeight: 1080.0
    property real uiScale: 1.0

    property real baseScale: LayoutMath.getScale(currentWidth, currentHeight, uiScale)
    
    function s(value) { 
        return LayoutMath.s(value, baseScale); 
    }
}