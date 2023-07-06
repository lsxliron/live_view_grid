declare module "table-dragger" {
  type EventTypes = "drop" | "drag" | "shadowMove" | "out"
  type DraggerMode = "row" | "column" | "free"

  type DragEventCallback = (el: HTMLElement, mode: DraggerMode) => any

  type OutEventCallback = DragEventCallback

  type DropEventCallback = (
    oldIndex: number,
    newIndex: number,
    el: HTMLElement,
    mode: DraggerMode
  ) => any

  type ShadowMoveCallback = DropEventCallback

  type TableDraggerEventCallback =
    | DragEventCallback
    | OutEventCallback
    | DropEventCallback
    | ShadowMoveCallback

  interface TableDraggerOptions {
    mode?: DraggerMode
    dragHandler?: string
    onlyBody?: boolean
    animation?: number
  }

  interface TableDraggerInstance {
    on: (eventType: EventTypes, e: TableDraggerEventCallback) => void
    destroy: () => void
  }

  export default function tableDragger(
    el: HTMLElement,
    options: TableDraggerOptions
  ): TableDraggerInstance
}
