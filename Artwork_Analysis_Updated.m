%%Program to read-resize-organize color images called from URL's and run
%%PCA for euclidian distance measures (similarity links) for artwork to
%%artwork network

%Read table and call urls for images -> RBG matrices

full_table = readtable('moma_parsed_new.xlsx'); % *(NEED TO RECHECK RAW DATA AND CORRECT ERRORS)*
[num,~] = size(full_table);
image_archive = cell(1,num); % Cell holder for all images

%NodeNo =  full_table(:,1);
ArtistNo = full_table(:,2);
RandNo = full_table(:,1);
Artists = full_table(:,4);
%ArtistNames =  full_table(:,5);
URLlist = string(table2array(full_table(:,6))); % URLs for all images

x=y+1;
for y = x:num
    options = weboptions('Timeout', 30); % If error, "Cannot read URL," run loop at error image count and continue 
    url_img = webread(URLlist(y), options);
    resized_img = imresize(url_img, [300 300]); % Make images same size for PCA
    image_archive{1,y} = resized_img; % save uint8 mtx times 3 (RBG) into cell
    if mod(y,50) == 0
        fprintf('Loading Image Number: %d\n', y);
    end
end

load chirp.mat;
sound(y);

for i = 1:num % Remove any B&W images based on uint8 size
    if sum(size(image_archive{i})) < 603
        image_archive(i) = [];
        ArtistNo(i,:) = [];
        Artists(i,:) = [];
        RandNo(i,:) = [];
        full_table(i,:) = [];
    end
end

image_archive_logic = cellfun('isempty', image_archive);
[~,num] = size(image_archive);
lister = [];
counter = 1;
for flow = 1:num
    test = image_archive_logic(flow);
    if test == 1
        lister(counter,1) = flow;
        counter = counter + 1;
    end
end
for flow2 = 1:counter-1
    image_archive(lister(flow2,1)) = [];
    ArtistNo(lister(flow2,1),:) = [];
    Artists(lister(flow2,1),:) = [];
    RandNo(lister(flow2,1),:) = [];
    full_table(lister(flow2,1),:) = [];
end

image_archive = image_archive(~cellfun('isempty',image_archive)); % Remove any B&W images based on uint8 size
[~, num] = size(image_archive);

%% Organize RNG mtx's for PCA (every rand ~2000), run PCA and save PCs

tPCAscore = [];
tPCApercent = [];
artist = [];
components = 500; % PCA components to use for downstream analysis

universalcountindex = [0];
universalcount = 1;

for groupno = 1:5 % Seperate total data into 5 parts to do PCA in chuncks (due to computational limitation)
    count = 1;
    clear group; clear randartist; clear holder; clear j;
    for j = 1:num % Edit ending range from new image_archive size
       
        if table2array(RandNo(j,1)) == groupno % Call random generated groups (1-5) for batch PCA computing
            holder = image_archive{j};
            holderR = reshape(holder(:,:,1)',[],1);
            holderB = reshape(holder(:,:,2)',[],1);
            holderG = reshape(holder(:,:,3)',[],1);
            holderRBG = vertcat(vertcat(holderR,holderB),holderG); % 1 long pixal vector for each image
            group(:,count) = holderRBG;
            randartist(count,:) = ArtistNo(j,1); % artist marking for each artwork loaded *(THIS NEEDS TO BE FIXED)*
            
            count = count + 1;
            universalcount = universalcount + 1;
            
            if mod(universalcount,50) == 0
                fprintf('Loading PCA Number: %d\n', universalcount);
            end
            
        end
    end
    universalcountindex(groupno+1,1) = universalcount - 1;
    [coeff,score,latent,~,explained] = pca(transpose(cast(group,'single'))); % Load PCA -(after transpose): row=artwork,column=PCs
    tPCAscore((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = score(:,1:components);
    tPCApercent(:,groupno) = explained(1:components,1); % Organize PCA data with correct artwork number
    artist((universalcountindex(groupno,1)+1):(universalcountindex(groupno+1,1)),:) = table2array(randartist);
end

%% PC distributions / figures and comparisons for artists/artworks

[~, num] = size(image_archive);
combinescore = [artist,tPCAscore];
%combinepercent = [artist,tPCApercent];
sortcombinescore = sortrows(combinescore);
%sortcombinepercent = sortrows(combinepercent);

artistsignal = zeros(2206,500);
cont = zeros(1,500);
count = 1;
for i = 1:2206
    for j = 1:num  
        if sortcombinescore(j,1) == i
            cont(count,:) = sortcombinescore(j,2:501);
            count = count + 1; 
        end
    end
    mu = mean(cont);
    artistsignal(i,:) = mu;
    clear container
    count = 1;
end

distance = [];
for m = 1:2206
    for n = 1:2206
    
    distance(n,m) = sum(abs(artistsignal(m,:)-artistsignal(n,:))); % Euclidian distance measures from
        
    end
end

figure(1);
grid on; axis square equal;
scatter3(tPCAscore(1:250,1),tPCAscore(1:250,2),tPCAscore(1:250,3),'.k');
% scatter(tPCAscore(:,1),tPCAscore(:,2),'o')
% title('PCA on All Artworks (~10000)')
% xlabel('PC1')
% ylabel('PC2')
hold on;
imageNum = 250;
imageWidth = 3000;
for i = 1:imageNum
    img = imresize(image_archive{i}, [imageWidth imageWidth]);
    x = tPCAscore(i,1);
    y = tPCAscore(i,2);
    z = tPCAscore(i,3);
    width = imageWidth;
    xImage = [x x+width; x x+width];   % The x data for the image corners
    yImage = [y y; y y];             % The y data for the image corners
    zImage = [z z; z-width z-width];   % The z data for the image corners
    surf(xImage,yImage,zImage,'CData',img,'FaceColor','texturemap');
end
xlabel('PCA1')
ylabel('PCA2')
zlabel('PCA3')

hold on
plot(1:100,tPCAscore(1,:))
plot(1:100,tPCAscore(4,:))
%% Nodes and Links

num = 2206;

for i = 1:num
    w(i,:) = (mink(distance(i,:),11));
end
weight = w(:,2:11); % Find 10 smallest distance differences from PCs (higher corralation between 2 nodes)

for i = 1:num
    for j = 1:10
        if sum(size(find(distance(i,:) == weight(i,j)))) > 2
            x = find(distance(i,:) == weight(i,j));
            finder(i,j) = x(1,1);
        else
            finder(i,j) = find(distance(i,:) == weight(i,j)); % Match node number with distance measures
        end
    end
end

v = [1:num];
u = repelem(v,10);

linkdesc1 = [u];
linkdesc2 = reshape(finder(:,:,1)',1,[]);
linkdesc3 = reshape(weight(:,:,1)',1,[]); % Organize data for node and edge arrays

Nodes = [1:2206]'; %Output for network software
Edges = [linkdesc1;linkdesc2;linkdesc3]'; %Output for network software
