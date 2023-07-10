import Sortable from "sortablejs"

Hooks = {}

/**
 * Adds a background color to a HTML element
 * @param {HTMLElement} cell the cell to apply the event on
 * @param {string} backgroundColor the hex color to set the background to
 * @returns {function} a callback the applies the event
 */
const toggleBackgroundColor = (cell, backgroundColor) => (e) => {
  const idx = cell.getAttribute("data-row-index")
  document.querySelectorAll(`div[data-row-index="${idx}"]`).forEach((c) => {
    c.style.backgroundColor = backgroundColor
  })
}

Hooks.Draggable = {
  mounted() {
    this.dragger = Sortable.create(this.el, {
      handle: ".draggable-table-header",
      sort: true,
      animation: 200,
      scroll: document.querySelector(".draggable-table-root"),
      bubbleScroll: true,
      scrollSensitivity: 30,
      onEnd: (evt) => {
        const newColumnOrder = Array.from(
          evt.to.querySelectorAll(".draggable-column-header-title")
        ).map((item) => item.innerText)
        this.pushEvent("set-columns", { columns: newColumnOrder })
      }
    })

    document.querySelectorAll(".sortable-table-cell").forEach((cell) => {
      cell.addEventListener("mouseover", toggleBackgroundColor(cell, "#c4b5fd"))
      cell.addEventListener("mouseout", toggleBackgroundColor(cell, ""))
    })
  }
}

window.LiveViewGrid = { Draggable: Hooks.Draggable }
