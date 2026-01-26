namespace :reports do
  desc 'Generate sales report (Excel), asks year if not provided'
  task :sales, [:year] => :environment do |_, args|
    year =
      if args[:year].present?
        args[:year].to_i
      else
        print 'Введите год (например 2025): '
        input = $stdin.gets&.strip

        unless input&.match?(/\A\d{4}\z/)
          puts '❌ Неверный год'
          exit(1)
        end

        input.to_i
      end

    file_path = SalesReportService.call(year)

    puts '✅ Отчёт сформирован'
    puts "  #{file_path}"
  end
end
