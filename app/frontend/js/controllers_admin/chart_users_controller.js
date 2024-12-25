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
    const response = await fetch(`/admin/analytics?type=users${params}`);
    const data = await response.json();

    this.renderChart(data.dates, data.users);
  }

  renderChart(dates, users) {
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
        show: true,
        borderColor: '#374151',
        strokeDashArray: 1,
      },
      series: [
        {
          name: "Пользователей",
          data: users,
        },
      ],
      xaxis: {
        categories: dates,
        labels: {
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
            return value;
          },
        },
      },
    };

    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
