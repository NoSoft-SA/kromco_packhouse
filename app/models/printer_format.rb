class PrinterFormat < ActiveRecord::Base


  def PrinterFormat.formats_for_label(label_code)
  
   query = "SELECT printer_formats.printer_format_code
            FROM
            public.label_printerformats
            INNER JOIN public.labels ON (public.label_printerformats.label_id = public.labels.id)
            INNER JOIN public.printer_formats ON (public.label_printerformats.printer_format_id = public.printer_formats.id)
            WHERE
            (public.labels.label_code = '#{label_code}')"
    return PrinterFormat.find_by_sql(query)
  
  
  end
end
