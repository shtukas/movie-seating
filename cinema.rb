
# encoding: UTF-8

require 'json'


# --------------------------------------------------------------------------
# Loading data from files

$people = IO.read('people.txt').lines.map{|line| line.strip }

#puts JSON.pretty_generate($people)

$relationships1 = IO.read('relationships.txt').lines.map{|line| line.strip }.map{|line| JSON.parse(line) }

#puts JSON.pretty_generate($relationships1)

$relationships_strenghts1 = IO.read('relationships-strenghts.txt').lines.map{|line| line.strip }.map{|line| line.split(',').map{|token| token.strip }   }

$relationships_strenghts2 = {}
$relationships_strenghts1.each{|item|
    $relationships_strenghts2[item[0]] = item[1].to_f
}

#puts JSON.pretty_generate($relationships_strenghts2)

# --------------------------------------------------------------------------
# Scoring a placement

def score(strenght,distance)
    strenght.to_f/distance
end

def score2(relationshiptype,distance)
    strenght = $relationships_strenghts2[relationshiptype]
    score(strenght,distance)
end

raise "score is incorrect" if score(12,4)!=3

def distance_between_two_people_in_placement(array,person1,person2)
    array = array.clone
    if array.first!=person1 and array.first!=person2 then
        array.shift
        return distance_between_two_people_in_placement(array.clone,person1,person2)
    end
    if array.last!=person1 and array.last!=person2 then
        array.pop
        return distance_between_two_people_in_placement(array.clone,person1,person2)
    end    
    array.size-1
end

raise "distance_between_two_people_in_placement is incorrect" if distance_between_two_people_in_placement(["aadya","shraddha","nick","sam","tracy","reetta","richard","pascal"],"nick","reetta")!=3
raise "distance_between_two_people_in_placement is incorrect" if distance_between_two_people_in_placement(["aadya","shraddha","nick","sam","tracy","reetta","richard","pascal"],"aadya","shraddha")!=1


def relationship_type_between_two_people(person1,person2)
    $relationships1.each{|relationship|
        if relationship.first == person1 and relationship.last == person2 then
            return relationship[1]
        end
    }
    $relationships1.each{|relationship|
        if relationship.first == person2 and relationship.last == person1 then
            return relationship[1]
        end
    }
    nil
end

raise "distance_between_two_people_in_placement is incorrect" if relationship_type_between_two_people('reetta','sam')!='friend'
raise "distance_between_two_people_in_placement is incorrect" if relationship_type_between_two_people('sam','reetta')!='friend'

def placement_score_core(placement,array,sum)
    head = array.shift
    tail = array # to avoid confusion
    if tail.size>0 then
        x = tail.map{|person|
            person1  = head   # for clarification
            person2  = person # for clarification
            relationship_type = relationship_type_between_two_people(person1,person2)
            if relationship_type.nil? then
                0
            else
                strenght = $relationships_strenghts2[relationship_type]
                distance = distance_between_two_people_in_placement(placement,person1,person2)
                score(strenght,distance)
            end
        }.inject(0,:+)
        placement_score_core(placement,tail.clone,sum+x)
    else
        sum
    end
end

def placement_score(placement)
    placement_score_core(placement.clone,placement.clone,0)
end

# --------------------------------------------------------------------------
# Manual Guess

placement = ["aadya","shraddha","nick","sam","tracy","reetta","richard","pascal"] # 22.183333333333334
placement = ["shraddha","aadya","sam","nick","tracy","pascal","reetta","richard"] # 32.75
placement = ["shraddha","aadya","sam","nick","pascal","tracy","reetta","richard"] # 33.25
placement = ["shraddha","sam","aadya","nick","pascal","tracy","reetta","richard"] # 32.1
placement = ["shraddha","tracy","pascal","sam","aadya","nick","reetta","richard"] # 33.33333333333333
placement = ["shraddha","tracy","pascal","sam","nick","aadya","reetta","richard"] # 30.383333333333333
placement = ["shraddha","tracy","pascal","aadya","sam","nick","reetta","richard"] # 33.66666666666667

if false then
    puts JSON.generate(placement.clone)
    puts placement_score(placement.clone)
    exit
end

# --------------------------------------------------------------------------
# Breakdown

def breakdown(placement)
    puts JSON.generate(placement)
    puts "data:"
    placement.combination(2).each{|pair|
        person1 = pair[0]
        person2 = pair[1]
        distance = distance_between_two_people_in_placement(placement,person1,person2)
        relationshiptype = relationship_type_between_two_people(person1,person2)
        next if relationshiptype.nil?
        puts "    #{person1.ljust(10)} #{person2.ljust(10)} #{distance.to_s.ljust(5)} #{relationshiptype.ljust(10)} #{score2(relationshiptype,distance)}"
    }
    puts placement_score(placement.clone)
end

if false then
    breakdown(["shraddha","tracy","pascal","aadya","sam","nick","reetta","richard"])
    exit
end

# --------------------------------------------------------------------------
# Automatic Search

if true then

    sortedresults = $people.permutation.map{|permutation|
        {
            'placement' => permutation,
            'score'     => placement_score(permutation)
        }
    }.sort{|o1,o2|
        o1['score']<=>o2['score']
    }


    # First we look for the biggest score
    score = placement_score(sortedresults.last['placement'])

    alreadydisplayedwinnershashes = [] 

    # Second we display all the winners but avoiding reversals
    $people.permutation.map{|permutation|
        {
            'placement' => permutation,
            'score' => placement_score(permutation)
        }
    }.select{|object|
        (object['score']-score).abs < 0.001
    }.each{|object|
        placement = object['placement']
        if !alreadydisplayedwinnershashes.include?( JSON.generate(placement) ) and !alreadydisplayedwinnershashes.include?( JSON.generate(placement.reverse) ) then
            alreadydisplayedwinnershashes << JSON.generate(placement)
            puts JSON.generate(object)
        end
    }

    # {"placement":["shraddha","tracy","pascal","nick","sam","aadya","reetta","richard"],"score":33.8}
    # {"placement":["shraddha","richard","reetta","nick","sam","aadya","pascal","tracy"],"score":33.8}    

    exit

end
