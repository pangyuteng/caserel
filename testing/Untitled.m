% str1 = 'http://results.chicagomarathon.com/2013/?page=';
% numPages = 18;
% str2 = '&event=MAR&lang=EN_CAP&num_results=1000&pid=list&search%5Bsex%5D=W';
% 
% out_table = {};
% for i = 1:numPages
% 	address = [str1 num2str(i) str2]
%     out_table = [out_table; getTableFromWeb_mod(address, 1)];
% end

out_table(2,4)
out_table(end,4)
id = strmatch('&#187; zzzzzzzzz (USA)',out_table(:,4));
out_table(id,:)
out_table(id,4)

ids = strmatch('20-24',out_table(:,7));

arrT = [];
for i = 1:numel(ids)
    arrT = [arrT; datenum(out_table{ids(i),11},'HH:MM:SS')];    
end

xax = min(arrT):(max(arrT)-min(arrT))/20:max(arrT)-(max(arrT)-min(arrT))/20;

bar(xax,histc(arrT,xax),1);

datetick

hold on;

plot(datenum(out_table(id,11),'HH:MM:SS'),100,'g.');


