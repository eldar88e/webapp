import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];
  static values = { time: { type: Number, default: 600 } };

  connect() {
    setTimeout(() => {
      this.last_week();
    }, this.timeValue);
  }

  last_week() {
    this.fetchData();
  }

  last_month() {
    this.fetchData("&period=month");
  }

  last_year() {
    this.fetchData("&period=year");
  }

  all() {
    this.fetchData("&period=all");
  }

  async fetchData(params = "") {
    const response = await fetch(`/admin/analytics?type=orders${params}`);
    const orders = await response.json();
    this.renderChart(orders);
  }

  renderChart(orders) {
    const label_translate = {
      processing: "В процессе",
      shipped: "Отправлен",
      overdue: "Просрочен",
      cancelled: "Отменен",
      refunded: "Возвращен",
    };

    const statusColors = {
      processing: "#ff8b4d",
      shipped: "#0e9f6e",
      overdue: "#831843",
      cancelled: "#E74694",
      refunded: "#1C64F2",
    };

    const statuses = Object.keys(Object.values(orders)[0] || {});

    const series = statuses.map((status) => ({
      name: label_translate[status] || status,
      data: Object.entries(orders).map(([date, counts]) => ({
        x: date,
        y: counts[status] || 0,
      })),
      color: statusColors[status] || "#999999",
    }));

    const options = {
      chart: {
        type: "line",
        height: 320,
      },
      stroke: {
        curve: "smooth",
      },
      xaxis: {
        type: "category",
      },
      legend: {
        position: "top",
      },
      grid: {
        show: true,
        borderColor: "#374151",
        strokeDashArray: 1,
      },
      series: series,
    };

    this.chartTarget.textContent = "";
    const chart = new ApexCharts(this.chartTarget, options);

    try {
      chart.render();
    } catch (error) {
      console.error("Error rendering chart:", error);
    }
  }
}
