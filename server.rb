module Application
  class Main < Sinatra::Base
    configure :development do
      register Sinatra::Reloader
    end

    configure :development, :production do
      enable :logging

      file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')

      file.sync = true

      use Rack::CommonLogger, file
    end

    register Sinatra::ConfigFile

    config_file 'config/settings.yml'

    get '/' do
      erb :index
    end

    get '/qr' do
      name = ''

      if params['last_name'].present?
        name += ';' + params['last_name'].to_s[0..30]
      end

      if params['first_name'].present?
        name += ';' + params['first_name'].to_s[0..30]
      end

      name.strip!

      formatted_name = "#{params['first_name'].to_s[0..30]} #{params['last_name'].to_s[0..30]}".strip

      organization = params['company'].to_s[0..64].strip

      title = params['title'].to_s[0..64].strip

      email = params['email'].to_s[0..255].strip

      phone = params['phone'].to_s[0..64].strip

      url = params['website'].to_s[0..512].strip

      if params['rev'].present?
        rev = params['rev'].to_s[0..32].strip
      else
        rev = Time.now.strftime('%Y%m%dT%H%M%SZ')
      end

      vcard = <<-eos.gsub(/^ {16}/, '')
                BEGIN:VCARD
                VERSION:2.1
                N:#{name}
                FN:#{formatted_name}
                ORG:#{organization}
                TITLE:#{title}
                EMAIL:#{email}
                TEL;TYPE=cell:#{phone}
                URL:#{url}
                REV:#{rev}
                END:VCARD
              eos

      logger.info "Generated VCard:\n#{vcard}"

      border = params['border'].present? && params['border'] != '0' && params['border'] != 'false'

      qr = RQRCode::QRCode.new(vcard, :size => vcard.length / 15, :level => :l)

      image = Magick::Image.new((qr.modules.length * 10) + (border ? 20 : 0), (qr.modules.length * 10) + (border ? 20 : 0)) do
        self.background_color = 'white'
      end

      qr.modules.each_index do |x|
        qr.modules.each_index do |y|
          if qr.dark?(x, y)
            square = Magick::Draw.new

            square.stroke('black').stroke_width(1)

            square.fill('black')

            square.rectangle((x * 10) + (border ? 10 : 0), (y * 10) + (border ? 10 : 0), (x * 10) + (border ? 20 : 10), (y * 10) + (border ? 20 : 10))

            square.draw(image)
          end
        end
      end

      image.format = 'png'

      content_type 'image/png'

      image.to_blob
    end

    post '/email' do
      content_type :json

      if params['email'].present?
        @base_url = "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"

        @query = "?first_name=#{params['last_name'].strip}&last_name=#{params['last_name'].strip}&email=#{params['email'].strip}&title=#{params['title'].strip}&company=#{params['company'].strip}&phone=#{params['phone'].strip}&website=#{params['website'].strip}&rev=#{Time.now.strftime('%Y%m%dT%H%M%SZ')}"

        logger.info "Sending email to #{params['email']}."

        begin
          Pony.mail(:to => params['email'], :subject => 'Your QR Code', :body => erb(:'email.text', :layout => false), :html_body => erb(:'email.html', :layout => false), :via => :smtp, :via_options => {
            :address => settings.smtp['address'],
            :port => settings.smtp['port'],
            :domain => settings.smtp['stmpdomain'],
            :authentication => settings.smtp['authentication'],
            :user_name => settings.smtp['user_name'],
            :password => settings.smtp['password'],
            :enable_starttls_auto => settings.smtp['enable_starttls_auto'].present? ? settings.smtp['enable_starttls_auto'] : false
          })

          logger.info "Sent email to #{params['email']}."

          { :status => 'success', :code => 200, :message => 'Email has been sent.' }.to_json
        rescue Exception => e
          logger.info "Failed to send email to #{params['email']}: #{e.message}"

          logger.info e.backtrace.inspect.to_s

          status 500

          { :status => 'error', :code => 500, :message => "Failed to send email. #{e.message}" }.to_json
        end
      else
        status 400

        { :status => 'error', :code => 400, :message => 'Email address is required.' }.to_json
      end
    end
  end
end
