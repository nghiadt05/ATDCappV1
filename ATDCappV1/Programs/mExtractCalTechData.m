function mExtractCalTechData
    global CalTechDataSetDir;
    minW = 32;
    minH = 64;
    
    if ~exist([CalTechDataSetDir '/train/'],'dir')
        mkdir([CalTechDataSetDir '/train/pos/']);
        mkdir([CalTechDataSetDir '/train/neg/']);

        % extract the Caltech dataset from compressed video sequences
        for s=1:2
          if(s==1), type='test'; skip=[]; else type='train'; skip=4; end
          mdbInfo(['Usa' type]); if(s==2), type=['train' int2str2(skip,2)]; end
          if(exist([CalTechDataSetDir type '/annotations'],'dir')), continue; end
          mdbExtract([CalTechDataSetDir type],1,skip);
        end

        % crop the person image from the extracted dataset    
        AnotationDir = dir([CalTechDataSetDir 'train04/annotations/*.txt']);
        ImagesDir = dir([CalTechDataSetDir 'train04/images/*.jpg']);
        for i=4829:size(AnotationDir,1)
            fprintf('Extracting sample images %d/%d ...',i,size(AnotationDir,1));
            anotationName = AnotationDir(i).name;
            imageName = ImagesDir(i).name;
            fid = fopen([CalTechDataSetDir 'train04/annotations/' anotationName],'r');
            im = imread([CalTechDataSetDir 'train04/images/' imageName]);
            isContainPerson = false;
            person_idx = 1;
            fgetl(fid); % this is the meaningless, ignore it
            tline = fgetl(fid);
            while ischar(tline)        
    %             disp(tline);
                if strcmp(tline(1:7),'person ')
                    personPos = str2num(tline(8:end));            
                    personPos = personPos(1:4);
                    if ( (personPos(3) >= minW) && (personPos(4) >= minH))
                        CropImage = im( max(personPos(2),1):min(personPos(2)+personPos(4),size(im,1)),...
                                        max(personPos(1),1):min(personPos(1)+personPos(3),size(im,2)),...
                                        :);             
                        isContainPerson = true;
        %                 figure();imshow(CropImage);
                        % save to the Caltech temporal positive-image directory
                        tmpName = sprintf('CalTech_%0.6d_%d.png',i,person_idx);
                        person_idx = person_idx + 1;
                        imwrite(CropImage,[CalTechDataSetDir '/train/pos/' tmpName]);
                    end            
                end
                tline = fgetl(fid);
            end
            fclose(fid);

            % if there is no person in the current image, save it to the temporal
            % negative-image directory
    %         if ~isContainPerson
    %             tmpName = sprintf('CalTech_%0.6d.png',i);
    %             imwrite(im,[CalTechDataSetDir '/train/neg/' tmpName]);
    %         end
        %     figure;imshow(im);    
            fprintf(' done\n');
        end
    end
end