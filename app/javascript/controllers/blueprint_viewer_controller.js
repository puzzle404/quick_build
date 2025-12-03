import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "canvas", "container", "zoomLevel",
        "scaleButton", "scaleButtonText", "scaleIndicator",
        "toolButton", "measurementsList",
        "materialModal", "materialList"
    ]

    static values = {
        imageUrl: String,
        blueprintId: String,
        projectId: String,
        scaleRatio: Number,
        measurements: Array,
        constructionItems: Object
    }

    connect() {
        this.canvas = this.canvasTarget
        this.ctx = this.canvas.getContext('2d')
        this.image = new Image()

        this.scale = 1
        this.offsetX = 0
        this.offsetY = 0
        this.isDragging = false

        this.currentTool = 'pan'
        this.groups = this.measurementsValue || []
        this.currentGroup = null

        this.drawingState = {
            active: false,
            points: [],
            currentPoint: null
        }

        this.setupCanvas()
        this.loadImage()
        this.setupEventListeners()
        this.renderMeasurementsList()
    }

    disconnect() {
        this.removeEventListeners()
    }

    setupCanvas() {
        const container = this.containerTarget
        this.canvas.width = container.clientWidth
        this.canvas.height = container.clientHeight
        window.addEventListener('resize', this.handleResize)
    }

    // Arrow function to auto-bind
    handleResize = () => {
        const container = this.containerTarget
        const oldWidth = this.canvas.width
        const oldHeight = this.canvas.height
        this.canvas.width = container.clientWidth
        this.canvas.height = container.clientHeight
        if (oldWidth > 0 && oldHeight > 0) {
            this.offsetX = this.offsetX * (this.canvas.width / oldWidth)
            this.offsetY = this.offsetY * (this.canvas.height / oldHeight)
        }
        this.draw()
    }

    loadImage() {
        this.image.onload = () => { this.fitImageToCanvas(); this.draw() }
        this.image.src = this.imageUrlValue
    }

    fitImageToCanvas() {
        const scaleX = this.canvas.width / this.image.width
        const scaleY = this.canvas.height / this.image.height
        this.scale = Math.min(scaleX, scaleY) * 0.9
        this.offsetX = (this.canvas.width - this.image.width * this.scale) / 2
        this.offsetY = (this.canvas.height - this.image.height * this.scale) / 2
        this.updateZoomLevel()
    }

    setupEventListeners() {
        this.canvas.addEventListener('mousedown', this.handleMouseDown)
        this.canvas.addEventListener('mousemove', this.handleMouseMove)
        this.canvas.addEventListener('mouseup', this.handleMouseUp)
        this.canvas.addEventListener('mouseleave', this.handleMouseLeave)
        this.canvas.addEventListener('wheel', this.handleWheel, { passive: false })
        this.canvas.addEventListener('touchstart', this.handleTouchStart, { passive: false })
        this.canvas.addEventListener('touchmove', this.handleTouchMove, { passive: false })
        this.canvas.addEventListener('touchend', this.handleTouchEnd)
    }

    removeEventListeners() {
        window.removeEventListener('resize', this.handleResize)
        this.canvas.removeEventListener('mousedown', this.handleMouseDown)
        this.canvas.removeEventListener('mousemove', this.handleMouseMove)
        this.canvas.removeEventListener('mouseup', this.handleMouseUp)
        this.canvas.removeEventListener('mouseleave', this.handleMouseLeave)
        this.canvas.removeEventListener('wheel', this.handleWheel)
        this.canvas.removeEventListener('touchstart', this.handleTouchStart)
        this.canvas.removeEventListener('touchmove', this.handleTouchMove)
        this.canvas.removeEventListener('touchend', this.handleTouchEnd)
    }

    // Arrow functions for event handlers
    handleMouseDown = (e) => {
        const coords = this.getPlaneCoordinates(e)

        if (this.currentTool === 'pan') {
            this.isDragging = true
            this.dragStartX = e.clientX - this.offsetX
            this.dragStartY = e.clientY - this.offsetY
            this.canvas.style.cursor = 'grabbing'
            return
        }

        if (this.currentTool === 'scale') {
            this.handleScaleClick(coords)
            return
        }

        if (!this.currentGroup) return

        if (this.currentTool === 'line') {
            if (!this.drawingState.active) {
                this.drawingState.active = true
                this.drawingState.points = [coords]
            } else {
                this.addMeasurement({ type: 'line', points: [this.drawingState.points[0], coords] })
                this.drawingState.active = false
                this.drawingState.points = []
            }
        } else if (this.currentTool === 'polygon') {
            if (!this.drawingState.active) {
                this.drawingState.active = true
                this.drawingState.points = [coords]
            } else {
                const first = this.drawingState.points[0]
                const dist = Math.hypot(coords.x - first.x, coords.y - first.y)
                if (dist < 10 / this.scale && this.drawingState.points.length >= 3) {
                    this.addMeasurement({ type: 'polygon', points: this.drawingState.points })
                    this.drawingState.active = false
                    this.drawingState.points = []
                } else {
                    this.drawingState.points.push(coords)
                }
            }
        } else if (this.currentTool === 'marker') {
            this.addMeasurement({ type: 'marker', point: coords })
        }
        this.draw()
    }

    handleMouseMove = (e) => {
        const coords = this.getPlaneCoordinates(e)
        if (this.currentTool === 'pan') {
            if (!this.isDragging) return
            this.offsetX = e.clientX - this.dragStartX
            this.offsetY = e.clientY - this.dragStartY
            this.draw()
            return
        }
        if (this.drawingState.active || this.currentTool === 'scale') {
            this.drawingState.currentPoint = coords
            this.draw()
        }
    }

    handleMouseUp = () => {
        if (this.currentTool === 'pan') {
            this.isDragging = false
            this.canvas.style.cursor = 'grab'
        }
    }

    handleMouseLeave = () => {
        this.isDragging = false
        if (this.currentTool === 'pan') this.canvas.style.cursor = 'grab'
    }

    handleWheel = (e) => {
        e.preventDefault()
        const delta = e.deltaY > 0 ? 0.9 : 1.1
        const mouseX = e.clientX - this.canvas.offsetLeft
        const mouseY = e.clientY - this.canvas.offsetTop
        this.zoomAtPoint(mouseX, mouseY, delta)
    }

    handleTouchStart = (e) => {
        e.preventDefault()
        if (e.touches.length === 1) {
            const touch = e.touches[0]
            this.isDragging = true
            this.dragStartX = touch.clientX - this.offsetX
            this.dragStartY = touch.clientY - this.offsetY
        }
    }

    handleTouchMove = (e) => {
        e.preventDefault()
        if (e.touches.length === 1 && this.isDragging) {
            const touch = e.touches[0]
            this.offsetX = touch.clientX - this.dragStartX
            this.offsetY = touch.clientY - this.dragStartY
            this.draw()
        }
    }

    handleTouchEnd = () => {
        this.isDragging = false
    }

    // ===== TOOL MANAGEMENT =====

    setTool(event) {
        const tool = event.currentTarget.dataset.tool

        if (tool === 'scale') {
            this.toggleScaleTool()
            return
        }

        if (this.currentTool === tool && !this.pendingModal) {
            this.resetToPan()
            return
        }

        if (this.currentGroup && this.currentGroup.type === tool) {
            this.activateTool(tool)
        } else {
            this.pendingTool = tool
            this.openMaterialModal(tool)
        }
    }

    activateTool(tool) {
        this.currentTool = tool
        this.updateToolUI(tool)
        this.canvas.style.cursor = 'crosshair'
        this.drawingState = { active: false, points: [], currentPoint: null }
        this.draw()
    }

    resetToPan() {
        this.currentTool = 'pan'
        this.currentGroup = null
        this.updateToolUI(null)
        this.canvas.style.cursor = 'grab'
        this.drawingState = { active: false, points: [], currentPoint: null }
        this.renderMeasurementsList()
        this.draw()
    }

    updateToolUI(activeTool) {
        this.toolButtonTargets.forEach(btn => {
            if (btn.dataset.tool === activeTool) {
                btn.dataset.active = "true"
            } else {
                delete btn.dataset.active
            }
        })
    }

    // ===== MATERIAL MODAL =====

    openMaterialModal(toolType) {
        this.materialModalTarget.classList.remove('hidden')
        this.renderMaterialList(toolType)
    }

    closeMaterialModal() {
        this.materialModalTarget.classList.add('hidden')
        this.pendingTool = null
        if (this.currentTool === 'pan') {
            this.resetToPan()
        }
    }

    renderMaterialList(toolType) {
        const items = this.constructionItemsValue
        const targetUnit = toolType === 'line' ? 'm' : toolType === 'polygon' ? 'm2' : 'un'
        let html = ''

        for (const [category, categoryItems] of Object.entries(items)) {
            const filteredItems = categoryItems.filter(item => item.unit === targetUnit)

            if (filteredItems.length > 0) {
                html += `<div class="px-4 py-2 text-xs font-semibold text-slate-500 bg-slate-50">${category}</div>`
                filteredItems.forEach(item => {
                    html += `
            <button type="button"
                    class="w-full px-4 py-3 text-left text-sm hover:bg-indigo-50 flex justify-between items-center group"
                    data-action="click->blueprint-viewer#selectMaterial"
                    data-id="${item.id}"
                    data-name="${item.name}">
              <span class="font-medium text-slate-700 group-hover:text-indigo-700">${item.name}</span>
              <span class="text-xs text-slate-400 group-hover:text-indigo-500">${item.unit}</span>
            </button>
          `
                })
            }
        }

        if (html === '') {
            html = `<div class="p-4 text-sm text-slate-500 text-center">No hay materiales disponibles para esta herramienta.</div>`
        }

        this.materialListTarget.innerHTML = html
    }

    selectMaterial(event) {
        const id = event.currentTarget.dataset.id
        const name = event.currentTarget.dataset.name
        this.createNewGroup(this.pendingTool, parseInt(id), name)
        this.closeMaterialModal()
    }

    selectNoMaterial() {
        const name = this.pendingTool === 'line' ? 'Medición Lineal' :
            this.pendingTool === 'polygon' ? 'Medición Área' : 'Conteo'
        this.createNewGroup(this.pendingTool, null, name)
        this.closeMaterialModal()
    }

    createNewGroup(type, itemId, name) {
        const color = this.generateColor(type)

        const newGroup = {
            id: crypto.randomUUID(),
            name: name,
            construction_item_id: itemId,
            type: type,
            color: color,
            elements: [],
            total_value: 0,
            unit: type === 'line' ? 'm' : type === 'polygon' ? 'm²' : 'un'
        }

        this.groups.push(newGroup)
        this.currentGroup = newGroup
        this.activateTool(type)
        this.renderMeasurementsList()
    }

    selectGroup(event) {
        const groupId = event.currentTarget.dataset.id
        const group = this.groups.find(g => g.id === groupId)

        if (group) {
            this.currentGroup = group
            this.activateTool(group.type)
            this.renderMeasurementsList()
        }
    }

    // ===== DRAWING & MEASUREMENT =====

    addMeasurement(data) {
        if (this.scaleRatioValue <= 0 && data.type !== 'marker') {
            alert("Primero debes definir la escala del plano.")
            return
        }

        let value = 0
        if (data.type === 'line') {
            const distPx = Math.hypot(data.points[1].x - data.points[0].x, data.points[1].y - data.points[0].y)
            value = distPx / this.scaleRatioValue
        } else if (data.type === 'polygon') {
            const areaPx = this.calculatePolygonArea(data.points)
            value = areaPx / (this.scaleRatioValue * this.scaleRatioValue)
        } else if (data.type === 'marker') {
            value = 1
        }

        const element = {
            id: crypto.randomUUID(),
            points: data.points || [data.point],
            point: data.point,
            value: value
        }

        if (this.currentGroup) {
            this.currentGroup.elements.push(element)
            this.recalculateGroupTotal(this.currentGroup)
            this.renderMeasurementsList()
            this.draw()
        }
    }

    recalculateGroupTotal(group) {
        group.total_value = group.elements.reduce((sum, el) => sum + el.value, 0)
    }

    // ===== RENDERING =====

    draw() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

        this.ctx.save()
        this.ctx.translate(this.offsetX, this.offsetY)
        this.ctx.scale(this.scale, this.scale)
        this.ctx.drawImage(this.image, 0, 0)
        this.ctx.restore()

        this.groups.forEach(group => {
            const isCurrent = this.currentGroup && this.currentGroup.id === group.id
            this.drawGroup(group, isCurrent)
        })

        if (this.drawingState.active) {
            this.drawCurrentTool()
        }

        if (this.currentTool === 'scale') this.drawScaleTool()
    }

    drawGroup(group, isCurrent) {
        this.ctx.save()
        this.ctx.translate(this.offsetX, this.offsetY)
        this.ctx.scale(this.scale, this.scale)

        const color = group.color || '#3b82f6'
        const opacity = isCurrent ? 1 : 0.6

        group.elements.forEach(el => {
            if (group.type === 'line') {
                this.ctx.strokeStyle = color
                this.ctx.lineWidth = (isCurrent ? 4 : 2) / this.scale
                this.ctx.globalAlpha = opacity
                this.ctx.beginPath()
                this.ctx.moveTo(el.points[0].x, el.points[0].y)
                this.ctx.lineTo(el.points[1].x, el.points[1].y)
                this.ctx.stroke()

                if (isCurrent) {
                    this.drawMeasurementLabel(el.points[0], el.points[1], `${el.value.toFixed(2)}m`, color)
                }

            } else if (group.type === 'polygon') {
                this.ctx.fillStyle = this.hexToRgba(color, 0.2)
                this.ctx.strokeStyle = color
                this.ctx.lineWidth = (isCurrent ? 3 : 1) / this.scale
                this.ctx.beginPath()
                el.points.forEach((p, i) => {
                    if (i === 0) this.ctx.moveTo(p.x, p.y)
                    else this.ctx.lineTo(p.x, p.y)
                })
                this.ctx.closePath()
                this.ctx.fill()
                this.ctx.stroke()

                if (isCurrent) {
                    const center = this.getPolygonCenter(el.points)
                    this.drawText(center, `${el.value.toFixed(2)}m²`, color)
                }

            } else if (group.type === 'marker') {
                const p = el.points[0] || el.point
                this.ctx.fillStyle = color
                this.ctx.beginPath()
                this.ctx.arc(p.x, p.y, (isCurrent ? 8 : 5) / this.scale, 0, Math.PI * 2)
                this.ctx.fill()
                this.ctx.strokeStyle = 'white'
                this.ctx.lineWidth = 2 / this.scale
                this.ctx.stroke()
            }
        })

        this.ctx.restore()
    }

    renderMeasurementsList() {
        if (!this.hasMeasurementsListTarget) return

        if (this.groups.length === 0) {
            this.measurementsListTarget.innerHTML = `<div class="text-center text-sm text-slate-500 py-8">No hay mediciones aún</div>`
            return
        }

        this.measurementsListTarget.innerHTML = this.groups.map(g => {
            const isCurrent = this.currentGroup && this.currentGroup.id === g.id
            const activeClass = isCurrent ? 'ring-2 ring-indigo-500 bg-indigo-50' : 'bg-slate-50 hover:bg-slate-100'

            return `
      <div class="p-3 rounded-lg border border-slate-200 cursor-pointer transition-all ${activeClass}"
           data-action="click->blueprint-viewer#selectGroup"
           data-id="${g.id}">
        <div class="flex items-center justify-between mb-1">
          <div class="flex items-center gap-2">
            <div class="w-3 h-3 rounded-full" style="background-color: ${g.color}"></div>
            <div class="text-sm font-medium text-slate-900">${g.name}</div>
          </div>
          <button type="button" 
                  data-action="click->blueprint-viewer#deleteGroup" 
                  data-id="${g.id}"
                  class="text-slate-400 hover:text-red-500 p-1">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
              <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 001.5.06l.3-7.5z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
        <div class="flex justify-between text-xs text-slate-500 pl-5">
          <span>${g.elements.length} tramos</span>
          <span class="font-semibold text-slate-700">${g.total_value.toFixed(2)} ${g.unit}</span>
        </div>
      </div>
    `}).join('')
    }

    deleteGroup(e) {
        e.stopPropagation()
        if (!confirm('¿Estás seguro de eliminar este grupo de mediciones?')) return

        const id = e.currentTarget.dataset.id
        this.groups = this.groups.filter(g => g.id !== id)
        if (this.currentGroup && this.currentGroup.id === id) {
            this.resetToPan()
        }
        this.renderMeasurementsList()
        this.draw()
    }

    async saveMeasurements() {
        try {
            const response = await fetch(
                `/constructors/projects/${this.projectIdValue}/blueprints/${this.blueprintIdValue}/update_measurements`,
                {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                    },
                    body: JSON.stringify({
                        blueprint: { measurements: { groups: this.groups } }
                    })
                }
            )

            const data = await response.json()
            if (data.success) {
                alert('Mediciones guardadas correctamente')
            } else {
                alert('Error al guardar: ' + data.errors.join(', '))
            }
        } catch (error) {
            console.error('Error:', error)
            alert('Error al guardar las mediciones')
        }
    }

    // ===== UTILS =====

    generateColor(type) {
        const colors = ['#ef4444', '#f97316', '#f59e0b', '#84cc16', '#10b981', '#06b6d4', '#3b82f6', '#6366f1', '#8b5cf6', '#d946ef', '#f43f5e']
        return colors[Math.floor(Math.random() * colors.length)]
    }

    hexToRgba(hex, alpha) {
        const r = parseInt(hex.slice(1, 3), 16)
        const g = parseInt(hex.slice(3, 5), 16)
        const b = parseInt(hex.slice(5, 7), 16)
        return `rgba(${r}, ${g}, ${b}, ${alpha})`
    }

    getPlaneCoordinates(e) {
        const rect = this.canvas.getBoundingClientRect()
        const x = e.clientX - rect.left
        const y = e.clientY - rect.top
        return { x: (x - this.offsetX) / this.scale, y: (y - this.offsetY) / this.scale }
    }

    zoomAtPoint(x, y, delta) {
        const newScale = this.scale * delta
        if (newScale < 0.1 || newScale > 10) return
        this.offsetX = x - (x - this.offsetX) * delta
        this.offsetY = y - (y - this.offsetY) * delta
        this.scale = newScale
        this.updateZoomLevel()
        this.draw()
    }

    updateZoomLevel() {
        if (this.hasZoomLevelTarget) this.zoomLevelTarget.textContent = `${Math.round(this.scale * 100)}%`
    }

    calculatePolygonArea(points) {
        let area = 0
        for (let i = 0; i < points.length; i++) {
            const j = (i + 1) % points.length
            area += points[i].x * points[j].y
            area -= points[j].x * points[i].y
        }
        return Math.abs(area / 2)
    }

    getPolygonCenter(points) {
        let x = 0, y = 0
        points.forEach(p => { x += p.x; y += p.y })
        return { x: x / points.length, y: y / points.length }
    }

    // Scale Tool Legacy
    toggleScaleTool() {
        if (this.currentTool === 'scale') {
            this.resetToPan()
        } else {
            this.resetToPan()
            this.currentTool = 'scale'
            this.drawingState = { active: false, points: [], currentPoint: null }
            if (this.hasScaleButtonTarget) this.scaleButtonTarget.dataset.active = "true"
            this.canvas.style.cursor = "crosshair"
            if (this.hasScaleButtonTextTarget) this.scaleButtonTextTarget.textContent = "Click para dibujar línea"
        }
    }

    handleScaleClick(coords) {
        if (!this.drawingState.active) {
            this.drawingState.active = true
            this.drawingState.points = [coords]
            if (this.hasScaleButtonTextTarget) this.scaleButtonTextTarget.textContent = "Click para finalizar"
        } else {
            this.scaleLineStart = this.drawingState.points[0]
            this.scaleLineEnd = coords
            this.showScaleInputModal()
            this.drawingState.active = false
            this.drawingState.points = []
        }
    }

    deactivateScaleTool() {
        if (this.hasScaleButtonTarget) delete this.scaleButtonTarget.dataset.active
        if (this.hasScaleButtonTextTarget) this.scaleButtonTextTarget.textContent = "Definir escala"
        this.scaleLineStart = null
        this.scaleLineEnd = null
    }

    showScaleInputModal() {
        const pixelDistance = Math.sqrt(Math.pow(this.scaleLineEnd.x - this.scaleLineStart.x, 2) + Math.pow(this.scaleLineEnd.y - this.scaleLineStart.y, 2))
        const realDistance = prompt(`Has dibujado una línea de ${Math.round(pixelDistance)} píxeles.\n\n¿Cuántos METROS representa esta distancia en la realidad?`)
        if (realDistance && !isNaN(realDistance) && parseFloat(realDistance) > 0) {
            this.saveScale(pixelDistance, parseFloat(realDistance))
        } else {
            alert('Distancia inválida.')
            this.deactivateScaleTool()
            this.resetToPan()
        }
    }

    async saveScale(pixelDistance, realDistance) {
        const scaleRatio = pixelDistance / realDistance
        try {
            const response = await fetch(`/constructors/projects/${this.projectIdValue}/blueprints/${this.blueprintIdValue}/update_scale`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content },
                body: JSON.stringify({ blueprint: { scale_ratio: scaleRatio } })
            })
            const data = await response.json()
            if (data.success) {
                this.scaleRatioValue = scaleRatio
                this.updateScaleIndicator(scaleRatio)
                this.deactivateScaleTool()
                this.resetToPan()
                this.draw()
                alert(data.message)
            } else {
                alert('Error: ' + data.errors.join(', '))
                this.deactivateScaleTool()
            }
        } catch (error) {
            console.error('Error:', error)
            alert('Error al guardar escala')
            this.deactivateScaleTool()
        }
    }

    updateScaleIndicator(scaleRatio) {
        if (this.hasScaleIndicatorTarget) this.scaleIndicatorTarget.textContent = `Escala: 1:${Math.round(scaleRatio)}`
    }

    drawScaleLine(start, end, isPreview = false) {
        this.ctx.save()
        this.ctx.translate(this.offsetX, this.offsetY)
        this.ctx.scale(this.scale, this.scale)
        this.ctx.strokeStyle = isPreview ? '#818cf8' : '#4f46e5'
        this.ctx.lineWidth = 2 / this.scale
        this.ctx.setLineDash(isPreview ? [5 / this.scale, 5 / this.scale] : [])
        this.ctx.beginPath()
        this.ctx.moveTo(start.x, start.y)
        this.ctx.lineTo(end.x, end.y)
        this.ctx.stroke()
        this.ctx.fillStyle = '#4f46e5'
        this.ctx.beginPath(); this.ctx.arc(start.x, start.y, 4 / this.scale, 0, Math.PI * 2); this.ctx.fill()
        this.ctx.beginPath(); this.ctx.arc(end.x, end.y, 4 / this.scale, 0, Math.PI * 2); this.ctx.fill()
        this.ctx.restore()
    }

    drawCurrentTool() {
        this.ctx.save()
        this.ctx.translate(this.offsetX, this.offsetY)
        this.ctx.scale(this.scale, this.scale)
        if (this.currentTool === 'line') {
            const start = this.drawingState.points[0]
            const current = this.drawingState.currentPoint
            if (start && current) {
                this.ctx.strokeStyle = '#ef4444'
                this.ctx.lineWidth = 2 / this.scale
                this.ctx.setLineDash([5 / this.scale, 5 / this.scale])
                this.ctx.beginPath()
                this.ctx.moveTo(start.x, start.y)
                this.ctx.lineTo(current.x, current.y)
                this.ctx.stroke()
                if (this.scaleRatioValue > 0) {
                    const distPx = Math.hypot(current.x - start.x, current.y - start.y)
                    const distM = distPx / this.scaleRatioValue
                    this.drawMeasurementLabel(start, current, `${distM.toFixed(2)}m`, '#ef4444')
                }
            }
        } else if (this.currentTool === 'polygon') {
            const points = this.drawingState.points
            const current = this.drawingState.currentPoint
            if (points.length > 0) {
                this.ctx.strokeStyle = '#3b82f6'
                this.ctx.lineWidth = 2 / this.scale
                this.ctx.setLineDash([5 / this.scale, 5 / this.scale])
                this.ctx.beginPath()
                points.forEach((p, i) => { if (i === 0) this.ctx.moveTo(p.x, p.y); else this.ctx.lineTo(p.x, p.y) })
                if (current) this.ctx.lineTo(current.x, current.y)
                this.ctx.stroke()
                this.ctx.fillStyle = '#3b82f6'
                points.forEach(p => { this.ctx.beginPath(); this.ctx.arc(p.x, p.y, 3 / this.scale, 0, Math.PI * 2); this.ctx.fill() })
            }
        }
        this.ctx.restore()
    }

    drawMeasurementLabel(p1, p2, text, color) {
        const midX = (p1.x + p2.x) / 2
        const midY = (p1.y + p2.y) / 2
        this.drawText({ x: midX, y: midY }, text, color)
    }

    drawText(pos, text, color) {
        this.ctx.font = `${14 / this.scale}px sans-serif`
        this.ctx.fillStyle = 'white'
        this.ctx.strokeStyle = 'black'
        this.ctx.lineWidth = 3 / this.scale
        this.ctx.textAlign = 'center'
        this.ctx.textBaseline = 'middle'
        this.ctx.strokeText(text, pos.x, pos.y)
        this.ctx.fillStyle = color || 'black'
        this.ctx.fillText(text, pos.x, pos.y)
    }

    zoomIn() { this.zoomAtPoint(this.canvas.width / 2, this.canvas.height / 2, 1.2) }
    zoomOut() { this.zoomAtPoint(this.canvas.width / 2, this.canvas.height / 2, 0.8) }
    resetView() { this.fitImageToCanvas(); this.draw() }
    showError() { }
}
