import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

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
        const response = await fetch(`/admin/analytics?type=orders${params}`);
        const data = await response.json();

        this.renderChart(data.dates, data.orders, data.total);
    }
    
    renderChart(labels, orders, total) {
        const label_translate = { "initialized": "Инициализирован", "unpaid": "Ожидание платежа",
            "pending": "Ожидание подтверждения платежа", "processing": "В процессе отправки", "shipped": "Отправлен",
            "cancelled": "Отменен", "overdue": "Просрочен" }
        const labels_rus = labels.map(label => label_translate[label] || label);
        const options = {
            series: orders,
            colors: ["#1C64F2", "#16BDCA", "#FDBA8C", "#E74694", "#775dd0"],
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
                                    fontFamily: "Inter, sans-serif",
                                    offsetY: 20,
                            },
                            total: {
                                showAlways: true,
                                    show: true,
                                    label: "Заказов",
                                    fontFamily: "Inter, sans-serif",
                                    formatter: function (w) {
                                    const sum = w.globals.seriesTotals.reduce((a, b) => {
                                        return a + b
                                    }, 0)
                                    return total
                                },
                            },
                            value: {
                                show: true,
                                    fontFamily: "Inter, sans-serif",
                                    offsetY: -20,
                                    formatter: function (value) {
                                    return value + "%"
                                },
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
                    fontFamily: "Inter, sans-serif",
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
        }

        this.chartTarget.textContent = '';
        const chart = new ApexCharts(this.chartTarget, options);
        chart.render();
    }
}
