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

  renderChart(data) {
    const label_translate = {
      initialized: "Инициализирован",
      unpaid: "Ожидание платежа",
      paid: "Ожидание подтверждения платежа",
      processing: "В процессе отправки",
      shipped: "Отправлен",
      cancelled: "Отменен",
      overdue: "Просрочен",
    };

    const statusColors = {
      initialized: "#16BDCA",
      unpaid: "#1C64F2",
      paid: "#775dd0",
      processing: "#ff8b4d",
      shipped: "#0e9f6e",
      cancelled: "#E74694",
      overdue: "#831843",
    };

    const statuses = Object.keys(Object.values(data)[0] || {});

    const series = statuses.map((status) => ({
      name: label_translate[status] || status,
      data: Object.entries(data).map(([date, counts]) => ({
        x: date,
        y: counts[status] || 0,
      })),
      color: statusColors[status] || "#999999"
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
        type: "datetime",
      },
      tooltip: {
        shared: true,
        intersect: false,
      },
      legend: {
        position: "top",
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
