import Draggable from './Draggable'

Hooks = {}

Hooks.Draggable = {
  mounted() {
    this.draggable = new Draggable(this)
    this.draggable.init()
  },
  updated() {
    this.draggable.updated()
  }
}
window.LiveViewGrid = {Draggable: Hooks.Draggable}
