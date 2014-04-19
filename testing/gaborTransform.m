function gaboredImgs = gaborTransform(img)
% initialize parameters for feature extraction
m_size = 10;
m_size_halfed = round((m_size)/2);
Fs = 0.2:0.1:0.5;
thetas= 0:2*pi/8:pi-2*pi/8;
sigmas = 2:2:6; % more or less features?

% initialize feature array
gaboredImgs = zeros([size(img),numel(sigmas),numel(thetas),numel(Fs)]);

for k = 1:numel(sigmas)
for j = 1:numel(Fs)
for i = 1:numel(thetas)


    sigma = sigmas(k);    
    F = Fs(j);
    theta = thetas(i);

    % setup the "gabor filter"
    [x,y]=meshgrid(-m_size_halfed:m_size_halfed,-m_size_halfed:m_size_halfed);
    g_sigma = (1./(2*pi*sigma^2)).*exp(((-1).*(x.^2+y.^2))./(2*sigma.^2));
    real_g = g_sigma.*cos((2*pi*F).*(x.*cos(theta)+y.*sin(theta)));
    im_g = g_sigma.*sin((2*pi*F).*(x.*cos(theta)+y.*sin(theta)));

    % perform Gabor transform
    uT =sqrt(conv2(img,real_g,'same').^2+conv2(img,im_g,'same').^2);
    
    % normalize image
    uT = (uT-mean(uT(:)))./std(uT(:));
    
    % save filtered image to feature array.
    gaboredImgs(:,:,k,i,j) = uT;
    
    % visualize filters
    %imagesc(uT);
% imagesc([real_g im_g]);
% colormap('gray'); axis image; axis off;
% title(sprintf('F:%1.2f t:%1.2f k:%1.f',F,theta,sigma));
% drawnow;
% ginput(1);

end
end
end