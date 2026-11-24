package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface UserRepository extends JpaRepository<User,Integer> {
    User findByEmail(String email);
    User findByEmailAndPassword(String email,String password);
}
