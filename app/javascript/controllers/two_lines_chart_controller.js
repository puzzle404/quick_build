import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { payload: Object }

  connect() {
    const payload = this.payloadValue || {}
    const defaultLabels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun']
    const labels = (payload.labels && payload.labels.length > 0) ? payload.labels : defaultLabels

    const canvas = this.element.querySelector('#myChart')
    if (!canvas) return

    const ctx = canvas.getContext('2d')

    // Create gradient for area fill
    const createGradient = (ctx, color1, color2) => {
      const gradient = ctx.createLinearGradient(0, 0, 0, 180)
      gradient.addColorStop(0, color1)
      gradient.addColorStop(1, color2)
      return gradient
    }

    // Light theme color palette
    const colors = {
      indigo: {
        line: '#6366f1',
        fill1: 'rgba(99, 102, 241, 0.15)',
        fill2: 'rgba(99, 102, 241, 0.01)'
      },
      emerald: {
        line: '#10b981',
        fill1: 'rgba(16, 185, 129, 0.15)',
        fill2: 'rgba(16, 185, 129, 0.01)'
      }
    }

    const series = (payload.series && payload.series.length > 0) ? payload.series : [
      { label: 'Etapas iniciadas', data: [0, 0, 0, 0, 0, 0], color: 'indigo' },
      { label: 'Etapas finalizadas', data: [0, 0, 0, 0, 0, 0], color: 'emerald' }
    ]

    const data = {
      labels: labels,
      datasets: series.map((s, i) => {
        const colorKey = i === 0 ? 'indigo' : 'emerald'
        const gradient = createGradient(ctx, colors[colorKey].fill1, colors[colorKey].fill2)

        return {
          label: s.label,
          data: s.data || [],
          borderColor: colors[colorKey].line,
          backgroundColor: gradient,
          borderWidth: 2,
          tension: 0.4,
          fill: true,
          pointRadius: 0,
          pointHoverRadius: 5,
          pointHoverBackgroundColor: colors[colorKey].line,
          pointHoverBorderColor: '#fff',
          pointHoverBorderWidth: 2
        }
      })
    }

    const config = {
      type: 'line',
      data: data,
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            align: 'end',
            labels: {
              color: '#64748b',
              font: { size: 11, weight: '500' },
              usePointStyle: true,
              pointStyle: 'circle',
              padding: 16,
              boxWidth: 6,
              boxHeight: 6
            }
          },
          tooltip: {
            backgroundColor: '#1e293b',
            titleColor: '#fff',
            bodyColor: 'rgba(255, 255, 255, 0.8)',
            borderColor: 'rgba(255, 255, 255, 0.1)',
            borderWidth: 1,
            padding: 10,
            cornerRadius: 8,
            displayColors: true,
            boxWidth: 6,
            boxHeight: 6,
            usePointStyle: true,
            titleFont: { size: 12, weight: '600' },
            bodyFont: { size: 11 }
          }
        },
        scales: {
          x: {
            ticks: {
              color: '#94a3b8',
              font: { size: 11 }
            },
            grid: {
              color: '#f1f5f9',
              drawBorder: false
            },
            border: { display: false }
          },
          y: {
            beginAtZero: true,
            ticks: {
              color: '#94a3b8',
              font: { size: 11 },
              padding: 8,
              stepSize: 1
            },
            grid: {
              color: '#f1f5f9',
              drawBorder: false
            },
            border: { display: false }
          }
        }
      }
    }

    const start = () => {
      if (window.Chart) {
        this.chart = new Chart(canvas, config)
        return true
      }
      return false
    }

    if (!start()) {
      let attempts = 0
      const iv = setInterval(() => {
        attempts += 1
        if (start() || attempts > 20) {
          clearInterval(iv)
        }
      }, 100)
    }
  }

  disconnect() {
    if (this.chart) this.chart.destroy()
  }
}
