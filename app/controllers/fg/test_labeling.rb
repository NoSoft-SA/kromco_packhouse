require "net/http"

  print_instruction = "<ProductLabel PID=\"223\" Status=\"true\" RunNumber=\"2010_PR_568_5_17Z\" Code=\"RW\" F0=\"E2\" F1=\"^0106002200087533100100568005\" F2=\"100009640431\" F3=\"FRL_FORELLE\" F4=\"PR\" F5=\"PEARS\" F6=\"TRU\" F7=\"T12D\" F8=\"112\" F9=\"UL\" F10=\"1L\" F11=\"0100568005\" F12=\"4122\" F13=\"E0178\" F14=\"GGN 4049928405838\" F15=\"LO_LOCAL\" F16=\"CLASS 1\" F17=\"8x1.5kg Bags; 1018\" F18=\"55mm+\" F19=\"TI\" F20=\"E0351\" F21=\"241\" F22=\"(01)06002200087533(10)0100568005\" F23=\"TRU-CAPE FRUIT MARKETING (PTY) LTD, PO Box 3772\" F24=\"SOMERSET WEST, 7129 PRODUCE OF SOUTH AFRICA\" F25=\"\" F26=\"\" F27=\"MARKING\" F28=\"TNC 27/NC10/2834/04\" F29=\"PR_FRL_CL1_1L_120_EC_UL_112_8B1.55RB*_CECD225_TI_NONE_TR_FRL_TRU_LGR\" F30=\"L_S_PNK\" F31=\"-\" Msg=\"OK\" />"
  http_conn = Net::HTTP.new("192.168.10.179", "2080")
  
 res =  http_conn.get("/" + print_instruction, nil)
 
 

#h = Net::HTTP.new('www.pragmaticprogrammer.com', 80)
#resp, data = h.get('/index.html', nil )
#puts "Code = #{resp.code}"
#puts "Message = #{resp.message}"

 #esp.each {|key, val| printf "%-14s = %-40.40s\n", key, val }
