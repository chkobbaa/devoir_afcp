package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin("*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<?> Register(@RequestBody User user) {
        if (userRepository.findByEmail(user.email) != null) {
            return ResponseEntity.status(409).body("Email already registered");
        }
        return ResponseEntity.ok(userRepository.save(user));
    }
    @PostMapping("/login")
    public User Login(@RequestBody User user) {
        User oldUSer = userRepository.findByEmailAndPassword(user.email, user.password);
        return oldUSer;
    }
}
