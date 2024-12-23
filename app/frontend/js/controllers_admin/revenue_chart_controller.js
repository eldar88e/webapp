import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];

  connect() {
    console.log('hi!');
    this.fetchRevenueData();
  }

  async fetchRevenueData() {
    const response = await fetch("/admin/analytics");
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
        size: 6,           // Размер точек
        colors: ['#0f80de'], // Цвет точек
        strokeColors: '#eef7ff', // Цвет обводки точек
        strokeWidth: 2,    // Ширина обводки
        hover: {
          size: 8,         // Размер точки при наведении
        },
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
          text: "Дата",
        },
      },
      yaxis: {
        title: {
          text: "Продажи",
        },
        labels: {
          formatter: function (value) {
            return `₽${value}`;
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

    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
