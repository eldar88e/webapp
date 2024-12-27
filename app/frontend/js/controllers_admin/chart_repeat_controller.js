import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";
import { I18n } from "i18n-js";
import ru from "./ru.json";

export default class extends Controller {
  static targets = ["chart"];

  async connect() {
    await this.last_week();
  }

  async last_week() {
    await this.fetchRevenueData();
  }

  async last_month() {
    await this.fetchRevenueData('&period=month');
  }

  async last_year() {
    await this.fetchRevenueData('&period=year');
  }

  async all() {
    await this.fetchRevenueData('&period=all');
  }

  async fetchRevenueData(params='') {
    const response = await fetch(`/admin/analytics?type=repeat${params}`);
    const data = await response.json();

    await this.renderChart(data[0], data[1]-data[0]);
  }

  async renderChart(repeat, one) {
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
          formatter: (value) => this.orderTitle(value),
        },
      },
      xaxis: {
        labels: {
          formatter: (value) => this.orderTitle(value),
        },
        axisTicks: {
          show: false,
        },
        axisBorder: {
          show: false,
        },
      },
    };

    this.chartTarget.textContent = '';
    const chart = new ApexCharts(this.chartTarget, options);

    try {
      await chart.render();
    } catch (error) {
      console.error("Error rendering chart:", error);
    }
  }

  getPluralForm(count) {
    const mod10 = count % 10;
    const mod100 = count % 100;

    if (mod10 === 1 && mod100 !== 11) {
      return "one";
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return "few";
    } else {
      return "many";
    }
  }

  orderTitle(count) {
    const i18n = new I18n();
    i18n.translations = { ru };
    i18n.locale = "ru";
    const pluralKey = this.getPluralForm(count);
    const result = i18n.t(`order.${pluralKey}`, { count });
    return `${count} ${result}`
  }
}
