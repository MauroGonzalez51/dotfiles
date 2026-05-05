.pragma library

function getScale(monitorWidth, monitorHeight, userScale) {
    if (arguments.length === 2) {
        userScale = monitorHeight;
        monitorHeight = monitorWidth * (1080.0 / 1920.0);
    }

    if (monitorWidth <= 0) {
        return 1.0;
    }

    if (monitorHeight <= 0) {
        return 1.0;
    }

    let relativeWidth = monitorWidth / 1920.0;
    let relativeHeight = monitorHeight / 1080.0;
    let minimumRatio = Math.min(relativeWidth, relativeHeight);

    let baseScale = 1.0;

    if (minimumRatio <= 1.0) {
        baseScale = Math.max(0.35, Math.pow(minimumRatio, 0.85));
    } else {
        baseScale = Math.pow(minimumRatio, 0.5);
    }

    if (userScale !== undefined) {
        return baseScale * userScale;
    }

    return baseScale;
}

function s(value, scale) {
    return Math.round(value * scale);
}