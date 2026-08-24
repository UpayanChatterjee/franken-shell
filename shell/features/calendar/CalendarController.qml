import QtQuick
import Quickshell

Scope {
    id: root

    required property var clockService
    property int firstDayOfWeek: 1
    readonly property var monthCells: controller.monthCells(state.visibleYear, state.visibleMonth, root.firstDayOfWeek)
    readonly property date selectedDate: state.selectedDate
    readonly property int visibleMonth: state.visibleMonth
    readonly property int visibleYear: state.visibleYear

    function selectDate(value: date) {
        const normalized = controller.localDate(value.getFullYear(), value.getMonth(), value.getDate());
        state.selectedDate = normalized;
        state.visibleYear = normalized.getFullYear();
        state.visibleMonth = normalized.getMonth();
    }
    function showNextMonth() {
        const next = controller.localDate(state.visibleYear, state.visibleMonth + 1, 1);
        state.visibleYear = next.getFullYear();
        state.visibleMonth = next.getMonth();
    }
    function showPreviousMonth() {
        const previous = controller.localDate(state.visibleYear, state.visibleMonth - 1, 1);
        state.visibleYear = previous.getFullYear();
        state.visibleMonth = previous.getMonth();
    }
    function showToday() {
        const today = root.clockService.now;
        root.selectDate(controller.localDate(today.getFullYear(), today.getMonth(), today.getDate()));
    }

    Component.onCompleted: root.showToday()

    QtObject {
        id: state

        property date selectedDate: new Date(0)
        property int visibleMonth: 0
        property int visibleYear: 1970
    }
    QtObject {
        id: controller

        function localDate(year: int, month: int, day: int): date {
            return new Date(year, month, day, 12, 0, 0, 0);
        }
        function monthCells(year: int, month: int, firstDay: int): var {
            const first = controller.localDate(year, month, 1);
            const normalizedFirstDay = Math.max(0, Math.min(6, firstDay));
            const leading = (first.getDay() - normalizedFirstDay + 7) % 7;
            const start = controller.localDate(year, month, 1 - leading);
            const cells = [];
            for (let index = 0; index < 42; index += 1) {
                const value = controller.localDate(start.getFullYear(), start.getMonth(), start.getDate() + index);
                cells.push(Object.freeze({
                    "date": value,
                    "day": value.getDate(),
                    "inVisibleMonth": value.getMonth() === month,
                    "selected": controller.sameDay(value, state.selectedDate),
                    "today": controller.sameDay(value, root.clockService.now),
                    "accessibleName": Qt.formatDate(value, "dddd, d MMMM yyyy")
                }));
            }
            return Object.freeze(cells);
        }
        function sameDay(left: date, right: date): bool {
            return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
        }
    }
}
