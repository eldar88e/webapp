import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];

  connect() {
      this.last_week();
  }

  last_week() {
      this.fetchRevenueData();
  }

  last_month() {
      this.fetchRevenueData('&period=month');
  }

  last_year() {
      this.fetchRevenueData('&period=year');
  }

  all() {
      this.fetchRevenueData('&period=all');
  }

  async fetchRevenueData(params='') {
    const response = await fetch(`/admin/analytics?type=revenue${params}`);
    const data = await response.json();

    this.renderChart(data.dates, data.revenues);
  }

  renderChart(dates, revenues) {
    const options = {
      chart: {
        type: "line",
        height: 350,
      },
      stroke: {
        curve: 'smooth',
      },
      markers: {
        size: 6,
        colors: ['#0f80de'],
        strokeColors: '#eef7ff',
        strokeWidth: 2,
        hover: {
          size: 8,
        },
      },
      grid: {
        show: true, // Показывать сетку
        borderColor: '#374151', // Цвет линий сетки
        strokeDashArray: 1, // Длина штрихов (пунктир)
      },
      series: [
        {
          name: "Продажи",
          data: revenues,
        },
      ],
      xaxis: {
        categories: dates,
        title: {
          //text: "Дата",
        },
        labels: {
          style: {
            colors: 'rgb(156, 163, 175);',
            fontSize: '14px',
            fontWeight: 700,
          },
        },
      },
      yaxis: {
        title: {
          // text: "Продажи",
        },
        labels: {
          formatter: function (value) {
            return `₽${value}`;
          },
          style: {
            colors: 'rgb(156, 163, 175);',
            fontSize: '14px',
            fontWeight: 700,
          },
        },
      },
      tooltip: {
        y: {
          formatter: function (value) {
            return `₽${value}`;
          },
        },
      },
    };

    this.chartTarget.textContent = '';
    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
