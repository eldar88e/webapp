import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"
import Localization from "./localization";

export default class extends Controller {
    static targets = ["chart"];

    async connect() {
        this.localization = new Localization("ru");
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
        const response = await fetch(`/admin/analytics?type=orders${params}`);
        const data = await response.json();

        await this.renderChart(data.dates, data.orders, data.total);
    }

    async renderChart(labels, orders, total) {
        const label_translate = { "initialized": "Инициализирован", "unpaid": "Ожидание платежа",
            "paid": "Ожидание подтверждения платежа", "processing": "В процессе отправки", "shipped": "Отправлен",
            "cancelled": "Отменен", "overdue": "Просрочен" }
        const labels_rus = labels.map(label => label_translate[label] || label);
        const options = {
            series: orders,
            colors: ["#775dd0", "#1C64F2", "#16BDCA", "#FDBA8C", "#E74694", "#775dd0", "#ff8b4d"],
            chart: {
            height: 320,
                width: "100%",
                type: "donut",
            },
            stroke: {
                colors: ["transparent"],
                    lineCap: "",
            },
            plotOptions: {
                pie: {
                    donut: {
                        labels: {
                            show: true,
                                name: {
                                show: true,
                                    fontFamily: "Montserrat, sans-serif",
                                    offsetY: 20,
                            },
                            total: {
                                showAlways: true,
                                    show: true,
                                    label: "Заказов",
                                    fontFamily: "Montserrat, sans-serif",
                                    formatter: function (w) {
                                    const sum = w.globals.seriesTotals.reduce((a, b) => {
                                        return a + b
                                    }, 0)
                                    return total
                                },
                            },
                            value: {
                                show: true,
                                fontFamily: "Montserrat, sans-serif",
                                offsetY: -20,
                                formatter: (value) => this.localization.orderTitle(value),
                            },
                        },
                        size: "80%",
                    },
                },
            },
            grid: {
                padding: {
                    top: -2,
                },
            },
            labels: labels_rus,
                dataLabels: {
                enabled: false,
            },
            legend: {
                position: "bottom",
                    fontFamily: "Montserrat, sans-serif",
            },
            yaxis: {
                labels: {
                    formatter: (value) => this.localization.orderTitle(value),
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
        }

        this.chartTarget.textContent = '';
        const chart = new ApexCharts(this.chartTarget, options);

        try {
            await chart.render();
        } catch (error) {
            console.error("Error rendering chart:", error);
        }
    }
}
