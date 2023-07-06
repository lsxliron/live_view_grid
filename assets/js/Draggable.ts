import tableDragger, { TableDraggerInstance } from "table-dragger"
import { ViewHook } from "phoenix_live_view"

class Draggable {
  dragger: TableDraggerInstance
  lv: ViewHook

  constructor(lv: ViewHook) {
    this.lv = lv
  }

  mounted() {
    this.init()
  }
  updated() {
    this.destroy()
    this.init()
  }

  init() {
    this.dragger = tableDragger(this.lv.el, {
      mode: "column",
      dragHandler: ".drag-handle"
    })
    this.dragger.on("drop", (_oldIndex, _newIndex, _el, _mode) => {
      const newColumnOrder = (
        Array.from(
          this.lv.el.querySelectorAll(".table-header")
        ) as Array<HTMLTableElement>
      ).map((item) => item.innerText)
      this.lv.pushEvent("set-columns", { columns: newColumnOrder })
    })
  }

  destroy() {
    this.dragger.destroy()
  }
}

export default Draggable
