import { Controller } from "@hotwired/stimulus"
import ApexCharts from "apexcharts"

export default class extends Controller {
    static targets = ["total", "unpaid", "pending", "processing", "shipped"];

    connect() {
        const total = Number(this.totalTarget.textContent) || 0;
        const unpaid = Number(this.unpaidTarget.textContent) || 0;
        const pending = Number(this.pendingTarget.textContent) || 0;
        const processing = Number(this.processingTarget.textContent) || 0;
        const shipped = Number(this.shippedTarget.textContent) || 0;

        const getChartOptions = () => {
            return {
                series: [unpaid, pending, processing, shipped],
                colors: ["#1C64F2", "#16BDCA", "#FDBA8C", "#E74694"],
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
            labels: ["Ожидание платежа", "Ожидание подтверждения платежа", "В процессе отправки", "Отправлено"],
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
        }

        if (document.getElementById("donut-chart") && typeof ApexCharts !== 'undefined') {
            const chart = new ApexCharts(document.getElementById("donut-chart"), getChartOptions());
            chart.render();

            // Get all the checkboxes by their class name
            const checkboxes = document.querySelectorAll('#devices input[type="checkbox"]');

            // Attach the event listener to each checkbox
            checkboxes.forEach((checkbox) => {
                checkbox.addEventListener('change', (event) => handleCheckboxChange(event, chart));
            });
        }
    }
}
