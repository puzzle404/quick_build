import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["canvas", "container", "zoomLevel", "scaleButton", "scaleButtonText", "scaleIndicator", "toolButton", "measurementsList"]
    static values = {
        imageUrl: String,
        blueprintId: String,
        projectId: String,
        scaleRatio: Number,
        measurements: Array
    }

    connect() {
        console.log("BlueprintViewerController connected")
        this.canvas = this.canvasTarget
        this.ctx = this.canvas.getContext('2d')
        this.image = new Image()

        // Estado del canvas
        this.scale = 1
        this.offsetX = 0
        this.offsetY = 0
        this.isDragging = false
        this.dragStartX = 0
        this.dragStartY = 0

        // Estado de herramientas
        this.currentTool = 'pan' // pan, scale, line, polygon, marker
        this.measurements = this.measurementsValue || []

        // Estado de dibujo temporal
        this.drawingState = {
            active: false,
            points: [],
            currentPoint: null // Para preview
        }

        // Bind methods
        this.handleResize = this.handleResize.bind(this)
        this.mouseDownHandler = this.handleMouseDown.bind(this)
        this.mouseMoveHandler = this.handleMouseMove.bind(this)
        this.mouseUpHandler = this.handleMouseUp.bind(this)
        this.mouseLeaveHandler = this.handleMouseLeave.bind(this)
        this.wheelHandler = this.handleWheel.bind(this)
        this.touchStartHandler = this.handleTouchStart.bind(this)
        this.touchMoveHandler = this.handleTouchMove.bind(this)
        this.touchEndHandler = this.handleTouchEnd.bind(this)

        // Configurar canvas
        this.setupCanvas()

        // Cargar imagen
        this.loadImage()

        // Event listeners
        this.setupEventListeners()

        // Renderizar lista inicial
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

    handleResize() {
        const container = this.containerTarget
        const oldWidth = this.canvas.width
        const oldHeight = this.canvas.height

        this.canvas.width = container.clientWidth
        this.canvas.height = container.clientHeight

        // Ajustar offset proporcionalmente
        if (oldWidth > 0 && oldHeight > 0) {
            this.offsetX = this.offsetX * (this.canvas.width / oldWidth)
            this.offsetY = this.offsetY * (this.canvas.height / oldHeight)
        }

        this.draw()
    }

    loadImage() {
        this.image.onload = () => {
            this.fitImageToCanvas()
            this.draw()
        }

        this.image.onerror = () => {
            console.error('Error al cargar la imagen del plano')
            this.showError()
        }

        this.image.src = this.imageUrlValue
    }

    fitImageToCanvas() {
        const canvasWidth = this.canvas.width
        const canvasHeight = this.canvas.height
        const imageWidth = this.image.width
        const imageHeight = this.image.height

        const scaleX = canvasWidth / imageWidth
        const scaleY = canvasHeight / imageHeight
        this.scale = Math.min(scaleX, scaleY) * 0.9

        this.offsetX = (canvasWidth - imageWidth * this.scale) / 2
        this.offsetY = (canvasHeight - imageHeight * this.scale) / 2

        this.updateZoomLevel()
    }

    draw() {
        // Limpiar canvas
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

        // 1. Dibujar imagen
        this.ctx.save()
        this.ctx.translate(this.offsetX, this.offsetY)
        this.ctx.scale(this.scale, this.scale)
        this.ctx.drawImage(this.image, 0, 0)
        this.ctx.restore()

        // 2. Dibujar mediciones guardadas
        this.drawMeasurements()

        // 3. Dibujar estado actual (dibujo en progreso o herramienta activa)
        if (this.currentTool === 'scale') {
            this.drawScaleTool()
        } else if (this.drawingState.active) {
            this.drawCurrentTool()
        }
    }

    drawMeasurements() {
        this.measurements.forEach(m => {
            this.ctx.save()
            this.ctx.translate(this.offsetX, this.offsetY)
            this.ctx.scale(this.scale, this.scale)

            if (m.type === 'line') {
                this.ctx.strokeStyle = '#ef4444' // Rojo
                this.ctx.lineWidth = 3 / this.scale
                this.ctx.beginPath()
                this.ctx.moveTo(m.points[0].x, m.points[0].y)
                this.ctx.lineTo(m.points[1].x, m.points[1].y)
                this.ctx.stroke()

                // Texto de medida
                this.drawMeasurementLabel(m.points[0], m.points[1], `${m.value.toFixed(2)}m`)

            } else if (m.type === 'polygon') {
                this.ctx.fillStyle = 'rgba(59, 130, 246, 0.3)' // Azul transparente
                this.ctx.strokeStyle = '#3b82f6'
                this.ctx.lineWidth = 2 / this.scale
                this.ctx.beginPath()
                m.points.forEach((p, i) => {
                    if (i === 0) this.ctx.moveTo(p.x, p.y)
                    else this.ctx.lineTo(p.x, p.y)
                })
                this.ctx.closePath()
                this.ctx.fill()
                this.ctx.stroke()

                // Texto en el centro
                const center = this.getPolygonCenter(m.points)
                this.drawText(center, `${m.value.toFixed(2)}m²`)

            } else if (m.type === 'marker') {
                this.ctx.fillStyle = '#10b981' // Verde
                this.ctx.beginPath()
                this.ctx.arc(m.point.x, m.point.y, 6 / this.scale, 0, Math.PI * 2)
                this.ctx.fill()
                this.ctx.strokeStyle = 'white'
                this.ctx.lineWidth = 2 / this.scale
                this.ctx.stroke()
            }

            this.ctx.restore()
        })
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

                // Calcular distancia en tiempo real
                if (this.scaleRatioValue > 0) {
                    const distPx = Math.hypot(current.x - start.x, current.y - start.y)
                    const distM = distPx / this.scaleRatioValue
                    this.drawMeasurementLabel(start, current, `${distM.toFixed(2)}m`)
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
                points.forEach((p, i) => {
                    if (i === 0) this.ctx.moveTo(p.x, p.y)
                    else this.ctx.lineTo(p.x, p.y)
                })
                if (current) this.ctx.lineTo(current.x, current.y)
                this.ctx.stroke()

                // Puntos vértices
                this.ctx.fillStyle = '#3b82f6'
                points.forEach(p => {
                    this.ctx.beginPath()
                    this.ctx.arc(p.x, p.y, 3 / this.scale, 0, Math.PI * 2)
                    this.ctx.fill()
                })
            }
        }

        this.ctx.restore()
    }

    drawScaleTool() {
        if (this.drawingState.points.length > 0 && this.drawingState.currentPoint) {
            this.drawScaleLine(this.drawingState.points[0], this.drawingState.currentPoint, true)
        }
    }

    drawMeasurementLabel(p1, p2, text) {
        const midX = (p1.x + p2.x) / 2
        const midY = (p1.y + p2.y) / 2
        this.drawText({ x: midX, y: midY }, text)
    }

    drawText(pos, text) {
        this.ctx.font = `${14 / this.scale}px sans-serif`
        this.ctx.fillStyle = 'white'
        this.ctx.strokeStyle = 'black'
        this.ctx.lineWidth = 3 / this.scale
        this.ctx.textAlign = 'center'
        this.ctx.textBaseline = 'middle'
        this.ctx.strokeText(text, pos.x, pos.y)
        this.ctx.fillText(text, pos.x, pos.y)
    }

    setupEventListeners() {
        this.canvas.addEventListener('mousedown', this.mouseDownHandler)
        this.canvas.addEventListener('mousemove', this.mouseMoveHandler)
        this.canvas.addEventListener('mouseup', this.mouseUpHandler)
        this.canvas.addEventListener('mouseleave', this.mouseLeaveHandler)
        this.canvas.addEventListener('wheel', this.wheelHandler, { passive: false })

        // Touch events
        this.canvas.addEventListener('touchstart', this.touchStartHandler, { passive: false })
        this.canvas.addEventListener('touchmove', this.touchMoveHandler, { passive: false })
        this.canvas.addEventListener('touchend', this.touchEndHandler)
    }

    removeEventListeners() {
        window.removeEventListener('resize', this.handleResize)
        this.canvas.removeEventListener('mousedown', this.mouseDownHandler)
        this.canvas.removeEventListener('mousemove', this.mouseMoveHandler)
        this.canvas.removeEventListener('mouseup', this.mouseUpHandler)
        this.canvas.removeEventListener('mouseleave', this.mouseLeaveHandler)
        this.canvas.removeEventListener('wheel', this.wheelHandler)

        this.canvas.removeEventListener('touchstart', this.touchStartHandler)
        this.canvas.removeEventListener('touchmove', this.touchMoveHandler)
        this.canvas.removeEventListener('touchend', this.touchEndHandler)
    }

    // ===== TOOL MANAGEMENT =====

    setTool(event) {
        const tool = event.currentTarget.dataset.tool

        // Desactivar herramienta anterior (si era escala)
        if (this.currentTool === 'scale') this.deactivateScaleTool()

        // Lógica de Toggle: Si clickeo la misma herramienta, la desactivo
        if (this.currentTool === tool) {
            this.currentTool = 'pan'
            this.toolButtonTargets.forEach(btn => delete btn.dataset.active)
            this.canvas.style.cursor = 'grab'
            this.drawingState = { active: false, points: [], currentPoint: null }
            this.draw()
            return
        }

        // Resetear estado de dibujo
        this.drawingState = { active: false, points: [], currentPoint: null }

        this.currentTool = tool

        // Actualizar UI: Solo el botón clickeado se activa
        this.toolButtonTargets.forEach(btn => {
            if (btn.dataset.tool === tool) {
                btn.dataset.active = "true"
            } else {
                delete btn.dataset.active
            }
        })

        // Cursor
        if (tool === 'pan') {
            this.canvas.style.cursor = 'grab'
        } else {
            this.canvas.style.cursor = 'crosshair'
        }

        this.draw()
    }

    // ===== MOUSE HANDLERS =====

    handleMouseDown(e) {
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

        if (this.currentTool === 'line') {
            if (!this.drawingState.active) {
                this.drawingState.active = true
                this.drawingState.points = [coords]
            } else {
                // Finalizar línea
                this.addMeasurement({
                    type: 'line',
                    points: [this.drawingState.points[0], coords]
                })
                this.drawingState.active = false
                this.drawingState.points = []
            }
        } else if (this.currentTool === 'polygon') {
            if (!this.drawingState.active) {
                this.drawingState.active = true
                this.drawingState.points = [coords]
            } else {
                // Detectar cierre (click cerca del primer punto)
                const first = this.drawingState.points[0]
                const dist = Math.hypot(coords.x - first.x, coords.y - first.y)

                if (dist < 10 / this.scale && this.drawingState.points.length >= 3) {
                    this.addMeasurement({
                        type: 'polygon',
                        points: this.drawingState.points
                    })
                    this.drawingState.active = false
                    this.drawingState.points = []
                } else {
                    this.drawingState.points.push(coords)
                }
            }
        } else if (this.currentTool === 'marker') {
            this.addMeasurement({
                type: 'marker',
                point: coords
            })
        }

        this.draw()
    }

    handleMouseMove(e) {
        const coords = this.getPlaneCoordinates(e)

        if (this.currentTool === 'pan') {
            if (!this.isDragging) return
            this.offsetX = e.clientX - this.dragStartX
            this.offsetY = e.clientY - this.dragStartY
            this.draw()
            return
        }

        // Actualizar preview
        if (this.drawingState.active || this.currentTool === 'scale') {
            this.drawingState.currentPoint = coords
            this.draw()
        }
    }

    handleMouseUp() {
        if (this.currentTool === 'pan') {
            this.isDragging = false
            this.canvas.style.cursor = 'grab'
        }
    }

    handleMouseLeave() {
        this.isDragging = false
        if (this.currentTool === 'pan') this.canvas.style.cursor = 'grab'
    }

    handleWheel(e) {
        e.preventDefault()
        const delta = e.deltaY > 0 ? 0.9 : 1.1
        const mouseX = e.clientX - this.canvas.offsetLeft
        const mouseY = e.clientY - this.canvas.offsetTop
        this.zoomAtPoint(mouseX, mouseY, delta)
    }

    // Touch handlers
    handleTouchStart(e) {
        e.preventDefault()
        if (e.touches.length === 1) {
            const touch = e.touches[0]
            this.isDragging = true
            this.dragStartX = touch.clientX - this.offsetX
            this.dragStartY = touch.clientY - this.offsetY
        }
    }

    handleTouchMove(e) {
        e.preventDefault()
        if (e.touches.length === 1 && this.isDragging) {
            const touch = e.touches[0]
            this.offsetX = touch.clientX - this.dragStartX
            this.offsetY = touch.clientY - this.dragStartY
            this.draw()
        }
    }

    handleTouchEnd() {
        this.isDragging = false
    }

    // ===== HELPERS =====

    getPlaneCoordinates(e) {
        const rect = this.canvas.getBoundingClientRect()
        const x = e.clientX - rect.left
        const y = e.clientY - rect.top
        return {
            x: (x - this.offsetX) / this.scale,
            y: (y - this.offsetY) / this.scale
        }
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
        if (this.hasZoomLevelTarget) {
            this.zoomLevelTarget.textContent = `${Math.round(this.scale * 100)}%`
        }
    }

    // ===== MEASUREMENT LOGIC =====

    addMeasurement(data) {
        if (this.scaleRatioValue <= 0 && data.type !== 'marker') {
            alert("Primero debes definir la escala del plano.")
            return
        }

        const measurement = {
            id: crypto.randomUUID(),
            ...data
        }

        // Calcular valores
        if (measurement.type === 'line') {
            const distPx = Math.hypot(
                measurement.points[1].x - measurement.points[0].x,
                measurement.points[1].y - measurement.points[0].y
            )
            measurement.value = distPx / this.scaleRatioValue
            measurement.unit = 'm'
            measurement.label = `Línea ${this.measurements.length + 1}`

        } else if (measurement.type === 'polygon') {
            const areaPx = this.calculatePolygonArea(measurement.points)
            measurement.value = areaPx / (this.scaleRatioValue * this.scaleRatioValue)
            measurement.unit = 'm²'
            measurement.label = `Área ${this.measurements.length + 1}`

        } else if (measurement.type === 'marker') {
            measurement.value = 1
            measurement.unit = 'ud'
            measurement.label = `Marcador ${this.measurements.length + 1}`
        }

        this.measurements.push(measurement)
        this.renderMeasurementsList()
        this.draw()
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

    renderMeasurementsList() {
        if (!this.hasMeasurementsListTarget) return

        if (this.measurements.length === 0) {
            this.measurementsListTarget.innerHTML = `
        <div class="text-center text-sm text-slate-500 py-8">
          No hay mediciones aún
        </div>`
            return
        }

        this.measurementsListTarget.innerHTML = this.measurements.map(m => `
      <div class="flex items-center justify-between p-3 bg-slate-50 rounded-lg border border-slate-200">
        <div>
          <div class="text-sm font-medium text-slate-900">${m.label}</div>
          <div class="text-xs text-slate-500">
            ${m.type === 'marker' ? 'Marcador' : `${m.value.toFixed(2)} ${m.unit}`}
          </div>
        </div>
        <button type="button" 
                data-action="click->blueprint-viewer#deleteMeasurement" 
                data-id="${m.id}"
                class="text-slate-400 hover:text-red-500">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-4 h-4">
            <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 001.5.06l.3-7.5z" clip-rule="evenodd" />
          </svg>
        </button>
      </div>
    `).join('')
    }

    deleteMeasurement(e) {
        const id = e.currentTarget.dataset.id
        this.measurements = this.measurements.filter(m => m.id !== id)
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
                        blueprint: { measurements: { items: this.measurements } }
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

    // ===== SCALE TOOL (Legacy adapter) =====

    toggleScaleTool() {
        if (this.currentTool === 'scale') {
            this.setTool({ currentTarget: { dataset: { tool: 'pan' } } })
        } else {
            this.currentTool = 'scale'
            this.drawingState = { active: false, points: [], currentPoint: null }

            // Resetear botones
            this.toolButtonTargets.forEach(btn => btn.dataset.active = "false")
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
            const start = this.drawingState.points[0]
            const end = coords

            // Guardar para renderizado legacy
            this.scaleLineStart = start
            this.scaleLineEnd = end

            this.showScaleInputModal()

            this.drawingState.active = false
            this.drawingState.points = []
        }
    }

    deactivateScaleTool() {
        if (this.hasScaleButtonTarget) this.scaleButtonTarget.dataset.active = "false"
        if (this.hasScaleButtonTextTarget) this.scaleButtonTextTarget.textContent = "Definir escala"
        this.scaleLineStart = null
        this.scaleLineEnd = null
    }

    showScaleInputModal() {
        const pixelDistance = Math.sqrt(
            Math.pow(this.scaleLineEnd.x - this.scaleLineStart.x, 2) +
            Math.pow(this.scaleLineEnd.y - this.scaleLineStart.y, 2)
        )

        const realDistance = prompt(
            `Has dibujado una línea de ${Math.round(pixelDistance)} píxeles.\n\n` +
            `¿Cuántos METROS representa esta distancia en la realidad?\n` +
            `(Ejemplo: una puerta estándar = 0.80)`
        )

        if (realDistance && !isNaN(realDistance) && parseFloat(realDistance) > 0) {
            this.saveScale(pixelDistance, parseFloat(realDistance))
        } else {
            alert('Distancia inválida. Intenta nuevamente.')
            this.deactivateScaleTool()
            this.setTool({ currentTarget: { dataset: { tool: 'pan' } } })
        }
    }

    async saveScale(pixelDistance, realDistance) {
        const scaleRatio = pixelDistance / realDistance

        try {
            const response = await fetch(
                `/constructors/projects/${this.projectIdValue}/blueprints/${this.blueprintIdValue}/update_scale`,
                {
                    method: 'PATCH',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
                    },
                    body: JSON.stringify({
                        blueprint: { scale_ratio: scaleRatio }
                    })
                }
            )

            const data = await response.json()

            if (data.success) {
                this.scaleRatioValue = scaleRatio
                this.updateScaleIndicator(scaleRatio)
                this.deactivateScaleTool()
                this.setTool({ currentTarget: { dataset: { tool: 'pan' } } })
                this.draw()
                alert(data.message)
            } else {
                alert('Error al guardar la escala: ' + data.errors.join(', '))
                this.deactivateScaleTool()
            }
        } catch (error) {
            console.error('Error:', error)
            alert('Error al guardar la escala')
            this.deactivateScaleTool()
        }
    }

    updateScaleIndicator(scaleRatio) {
        if (this.hasScaleIndicatorTarget) {
            this.scaleIndicatorTarget.textContent = `Escala: 1:${Math.round(scaleRatio)}`
        }
    }

    // Helpers de botones
    zoomIn() { this.zoomAtPoint(this.canvas.width / 2, this.canvas.height / 2, 1.2) }
    zoomOut() { this.zoomAtPoint(this.canvas.width / 2, this.canvas.height / 2, 0.8) }
    resetView() { this.fitImageToCanvas(); this.draw() }
    showError() { /* ... */ }

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

        // Dibujar puntos en los extremos
        this.ctx.fillStyle = '#4f46e5'
        this.ctx.beginPath()
        this.ctx.arc(start.x, start.y, 4 / this.scale, 0, Math.PI * 2)
        this.ctx.fill()

        this.ctx.beginPath()
        this.ctx.arc(end.x, end.y, 4 / this.scale, 0, Math.PI * 2)
        this.ctx.fill()

        this.ctx.restore()
    }
}
