class ReturnjsonsController < ApplicationController
  def getquestion
    @questions = Question.where(isnew:'0')
    render json:(@questions)
  end

  def getanswer
    @answers=Answer.all
    render json:(@answers)
  end

  def updatecheck
    @updatecheck = Updatecheck.all
    render json:(@updatecheck)
  end

  def chapter
    @chapters = Chapter.all
    render json:(@chapters)
  end

  def subject
    @subjects = Subject.all

    render json:(@subjects)
  end

  def getvalidate
    myuser = User.find_by_login(params[:login])
    myuuid=UUIDTools::UUID.timestamp_create
    if myuser
      myuser.remoteval=myuuid
      myuser.save
      if myuser.logintype=='0'
      render json:('[{"validate":"'+myuuid+'","value":"'+myuser.loginnumber.to_s+'","status":"'+myuser.status+'"}]')
      else
        render json:('[{"validate":"'+myuuid+'","value":"'+myuser.logintime.to_s+'","status":"'+myuser.status+'"}]')
        end
    end
  end

  def getuser


    loc=''
    location = getip(params[:ip])
    location_json = JSON.parse(location)
    10.times do
      begin
        loc = location_json['retData']['province']+'省 '+location_json['retData']['city']+'市 '+location_json['retData']['carrier']
      rescue
        loc=''
      end
      if loc != ''
        break
      end
    end


    login=params[:login]
    validate=params[:validate]
#login = 'add86'

    myuser=User.find_by_login(login)
    myvalidate=::Digest::MD5.hexdigest(myuser.login+myuser.password+myuser.remoteval+'CLOUDTIMESOFT')

    myvalidate.to_s.upcase!    #if myvalidate == validate && Time.parse(myvalidate.updated_at)
    usertime= myuser.updated_at
    nowtime=Time.now
    if nowtime - DateTime.parse(usertime.to_s) < 100 && validate==myvalidate
      render json:(myuser)
      #debugger

      #debugger
      #'http://apis.baidu.com/apistore/iplookupservice/iplookup?ip=117.89.35.58 -H apikey:6e1802f8c0cd1b42b32249ba42c2e602y'


      #location = getip(params[:ip])

      myuser.loginnumber= myuser.loginnumber.to_i - 1
      myuser.save

      Loginlog.create(user_id:myuser.id,ip:params[:ip],location:loc)
    else
      render json:('[{"status":"error"}]')
    end

  end



  def changepassword
    oldpassword=params[:oldpassword]
    newpassword=params[:newpassword]
    login=params[:login]
    user =User.find_by_login(login)
    hexpassword=::Digest::MD5.hexdigest(user.password).to_s.upcase!
    if hexpassword == oldpassword
      user.password=newpassword
      user.save
      render json:('[{"status":"密码修改成功！"}]')
    else
      render json:('[{"status":"原始密码不正确！"}]')
    end




  end


  def r_errquests

    errquestions = Errquest.where(user_id:params[:user_id])
    render json:(errquestions)

  end

  def t_errquests

    del = params[:command]
    questions =params[:q]
    amounts=params[:a]
    userid=params[:user_id]

    if del != nil
      delerr = Errquest.where(user_id:userid)
      delerr.each do |del|
        del.destroy
      end
    end

    step=0
    Errquest.transaction do
    if(questions!=nil)
      questions.each do |f|
        Errquest.create(user_id:userid,question_id:f,amount:amounts[step])
        step=step+1
      end
    end
    end



    #debugger
     # Errquest.create(question_id:params[:login])
      render json:('[{"status":"原始密码不正确！"}]')
  end


#url => 'http://apis.baidu.com'
private
def getip(ip)
  conn = Faraday.new(:url => 'http://apis.baidu.com') do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
  end
  conn.headers[:apikey] = '6e1802f8c0cd1b42b32249ba42c2e602'
  conn.params[:ip]=ip
  request = conn.get do |req|
    req.url '/apistore/iplookup/iplookup_paid'
  end
  return request.body
  debugger
end








end
