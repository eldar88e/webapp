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
      },
    };

    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
