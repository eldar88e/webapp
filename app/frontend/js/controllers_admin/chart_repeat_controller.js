import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];

  connect() {
    this.fetchRevenueData();
  }

  last_month(event) {
    event.preventDefault();
    //console.log('sdf');
    this.fetchRevenueData('&period=month');
  }

  async fetchRevenueData(params='') {
    const response = await fetch(`/admin/analytics?type=repeat${params}`);
    const data = await response.json();

    this.renderChart(data[0], data[1]-data[0]);
  }

  renderChart(repeat, one) {
    const options = {
      series: [repeat, one],
      colors: ["#1C64F2", "#16BDCA"],
      chart: {
        height: 320,
        width: "100%",
        type: "pie",
      },
      stroke: {
        colors: ["white"],
        lineCap: "",
      },
      plotOptions: {
        pie: {
          labels: {
            show: true,
          },
          size: "100%",
          dataLabels: {
            offset: -25
          }
        },
      },
      labels: ["Повторные", "Единоразовые"],
      dataLabels: {
        enabled: true,
      },
      legend: {
        position: "bottom",
      },
      yaxis: {
        labels: {
          formatter: function (value) {
            return value + "%"
          },
        },
      },
      xaxis: {
        labels: {
          formatter: function (value) {
            return value  + "%"
          },
        },
        axisTicks: {
          show: false,
        },
        axisBorder: {
          show: false,
        },
      },
    };

    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
