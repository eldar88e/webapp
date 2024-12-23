import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];

  connect() {
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
        size: 6,
        colors: ['#0f80de'],
        strokeColors: '#eef7ff',
        strokeWidth: 2,
        hover: {
          size: 8,
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
